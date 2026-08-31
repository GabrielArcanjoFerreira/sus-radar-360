# Select AI — perguntas em linguagem natural

Permite que um gestor pergunte em português, direto no banco, sem escrever SQL:

```sql
SELECT AI Quais regiões de SP estão em alerta vermelho;
```

O Oracle lê a pergunta, olha as views da Gold e os comentários de cada coluna, escreve o SQL, executa e devolve a resposta. Todo o processamento é no Autonomous Database — o dado não sai do banco, só a pergunta e a estrutura das tabelas vão para o modelo de linguagem.

> **Estado: montado e validado, aguardando um provedor de modelo.** Toda a infraestrutura está criada e as sete views respondem às seis perguntas do contrato. O que falta é o LLM: a tenancy `greatminds2026` tem **cota zero** no OCI Generative AI. Leia [O bloqueio do provedor](#o-bloqueio-do-provedor) — tem duas saídas, uma delas gratuita.

---

## Links

| Para quê | URL |
|---|---|
| **Rodar Select AI** — SQL no navegador | https://GD2DC045E9D5DD9-SUSRADAR.adb.us-ashburn-1.oraclecloudapps.com/ords/sql-developer |
| Worksheet direto no schema GOLD | https://GD2DC045E9D5DD9-SUSRADAR.adb.us-ashburn-1.oraclecloudapps.com/ords/gold/_sdw/ |
| APEX — para montar a tela de chat | https://GD2DC045E9D5DD9-SUSRADAR.adb.us-ashburn-1.oraclecloudapps.com/ords/apex |
| Console da OCI — cotas do Generative AI | https://cloud.oracle.com/limits?region=us-ashburn-1 |

Entre como **`GOLD`** (senha em `docs/acesso.md`). É o schema que tem o perfil e as views.

---

## As três perguntas que o Select AI responde de três jeitos

```sql
-- 1. a resposta pronta
SELECT AI Quais regiões de SP estão em alerta vermelho;

-- 2. o SQL que ele escreveu, sem executar — use para conferir antes de confiar
SELECT AI showsql Quais regiões de SP estão em alerta vermelho;

-- 3. a explicação em texto corrido, para colar num relatório
SELECT AI narrate Quais regiões de SP estão em alerta vermelho;
```

Fora da sintaxe curta, dá para chamar como função:

```sql
SELECT DBMS_CLOUD_AI.GENERATE(
         prompt       => 'Quais regiões pioraram no último semestre?',
         profile_name => 'SUSRADAR',
         action       => 'showsql') FROM dual;
```

---

## O que foi criado

### Na OCI

| Recurso | Identificador | Para quê |
|---|---|---|
| Policy | `susradar-adb-genai` | `Allow dynamic-group susradar-adb to use generative-ai-family in tenancy` |

O banco se autentica por **resource principal** — a mesma identidade que já lê o Object Storage. Não há chave de API guardada em lugar nenhum.

### No banco

| Objeto | Onde | O que é |
|---|---|---|
| Perfil `SUSRADAR` | `GOLD` | a configuração do Select AI: provedor, modelo e a lista de tabelas visíveis |
| 7 views + 1 tabela | `GOLD` | o que o modelo enxerga — nada de Bronze, nada de Silver |
| 116 comentários | `GOLD` | a camada semântica, o que ensina o modelo a acertar |

Arquivos, na ordem de execução:

```
sql/04_select_ai/00_habilita.sql          como ADMIN, uma vez
sql/04_select_ai/01_camada_semantica.sql  como GOLD
sql/04_select_ai/02_perfil.sql            como GOLD
sql/04_select_ai/03_provedor_google.sql   plano B, se for usar chave própria
sql/04_select_ai/99_perguntas.sql         o gabarito das seis perguntas
```

---

## As views expostas

O modelo só enxerga estas oito. A lista é curta de propósito: cada objeto a mais entra no prompt, gasta contexto e dá mais chance de o modelo escolher a tabela errada.

| View | Grão | Serve para |
|---|---|---|
| `VW_IPA_REGIAO` | região | **o contrato do protótipo.** Ranking de pressão nos últimos 12 meses |
| `VW_PAINEL_REGIAO_MENSAL` | região × mês | tendência, evolução, comparação entre períodos |
| `VW_PAINEL_MUNICIPIO_MENSAL` | município × mês | perguntas por município, com nome e coordenada |
| `VW_PAINEL_HOSPITAL` | hospital × mês | desempenho por estabelecimento, com a média estadual ao lado |
| `VW_MORBIDADE_REGIAO_MENSAL` | região × mês × capítulo CID | perguntas por doença — respiratório é o capítulo `J` |
| `VW_FLUXO_REGIAO` | par de regiões | quem sai da própria região para se internar |
| `VW_VITAL_REGIAO_ANUAL` | região × ano | óbitos (SIM) e nascidos vivos (SINASC) |
| `GLD_FAIXA_RISCO` | — | os pontos de corte do semáforo |

### O contrato

O protótipo da Sprint 1 fechou a assinatura mínima. Ela existe e responde:

```sql
SELECT regiao_saude, ipa, semaforo FROM VW_IPA_REGIAO
WHERE semaforo = 'VERMELHO' ORDER BY ipa DESC;
```

Resultado hoje, sobre junho/2025 a maio/2026:

| Semáforo | Regiões | IPA |
|---|---|---|
| VERDE | 29 | 22,00 – 48,80 |
| AMARELO | 32 | 50,29 – 73,94 |
| VERMELHO | 1 | 75,88 |

**62 de 62 regiões classificadas.** É o critério de aceite "100% das regiões de SP classificadas em verde, amarelo ou vermelho", cumprido.

---

## A camada semântica

É a parte que decide se o Select AI acerta ou inventa. O perfil é criado com `comments => 'true'`, então **todo `COMMENT ON` vai literalmente no prompt do modelo**, junto do DDL. Coluna sem comentário é coluna que o modelo adivinha.

As regras usadas em `01_camada_semantica.sql`:

1. **Dizer a unidade e o grão.** "percentual de 0 a 100", "uma linha por região e por mês".
2. **Listar os valores quando o domínio é fechado.** `semaforo` diz, com todas as letras, que só existe `VERDE`, `AMARELO` e `VERMELHO`.
3. **Ensinar o vocabulário do gestor.** Ninguém pergunta "IPA acima de 75". Perguntam "quais regiões estão em alerta", "onde está sobrecarregado", "quem está no vermelho". O comentário de `semaforo` diz que VERMELHO *é* o alerta vermelho.
4. **Avisar do que não dá para responder.** O comentário de `VW_VITAL_REGIAO_ANUAL` diz que óbitos cobrem 2021–2024 e internações 2024–2026, e manda não cruzar por ano. Sem isso o modelo cruzaria e devolveria zeros com cara de resposta.

Exemplo do que está gravado:

```sql
COMMENT ON COLUMN vw_ipa_regiao.semaforo IS
'Classificacao de risco em tres cores. Valores possiveis, exatamente estes:
 VERDE, AMARELO, VERMELHO. VERMELHO significa IPA de 75 por cento ou mais e e o
 que o gestor chama de alerta vermelho, regiao critica ou regiao em alerta.';
```

---

## As seis perguntas do contrato

Todas foram respondidas com SQL escrito à mão contra as views, em `99_perguntas.sql`. Isso separa dois problemas que sempre se confundem: se o Select AI errar, já se sabe que **não é o modelo de dados** — as views suportam a pergunta.

| # | Pergunta | View | Resultado real |
|---|---|---|---|
| 1 | Regiões em alerta vermelho | `VW_IPA_REGIAO` | Franco da Rocha, IPA 75,88 |
| 2 | Municípios com maior aumento no trimestre | `VW_PAINEL_MUNICIPIO_MENSAL` | Registro +70,3%, Ferraz de Vasconcelos +70,0% |
| 3 | Hospitais acima da permanência média estadual | `VW_PAINEL_HOSPITAL` | média do estado 5,02 dias; o topo passa de 30 |
| 4 | Internações × leitos por região | `VW_IPA_REGIAO` | Jundiaí lidera, 69,6 internações por leito ao ano |
| 5 | Onde a pressão respiratória cresce mais | `VW_MORBIDADE_REGIAO_MENSAL` | só Rio Claro cresce (+7,8%); o resto do estado cai |
| 6 | Regiões que pioraram entre semestres | `VW_PAINEL_REGIAO_MENSAL` | Vale do Paraíba/Região Serrana, +5,3 pontos de IPA |

E uma que só existe porque a ingestão usou microdado em vez de TABNET agregado:

> **Quais regiões mandam o próprio morador se internar fora?**
> José Bonifácio 56,3% · Pontal do Paranapanema 50,5% · Alta Paulista 49,1%.

Dado agregado não tem o par `MUNIC_RES` × `MUNIC_MOV` e não responde isso.

### Duas ressalvas sobre os números acima

- **Pergunta 3.** Os hospitais no topo têm ~30 dias de permanência média porque são unidades de longa permanência, não porque estão ineficientes. É a mesma ressalva do IPA descrita em [gold.md](gold.md).
- **Pergunta 5.** Internações respiratórias estão **caindo** em quase todo o estado. A pergunta continua válida, a resposta é que hoje quase não há pressão respiratória crescendo.

---

## O bloqueio do provedor

Tudo está montado. O que falta é o modelo de linguagem.

### O que acontece

Qualquer chamada volta:

```
ORA-20404: Object not found - https://inference.generativeai.us-ashburn-1.oci.my$cloud_domain/20231130/actions/chat
```

### O que **não** é

O `my$cloud_domain` na mensagem assusta, mas é só o template usado no texto do erro. Com uma região inexistente o erro mostra a URL já montada — `https://inference.generativeai.xx-nowhere-1.oci.oraclecloud.com/...` — prova de que a substituição funciona e o host real é contatado.

Também não é configuração do banco. Resource principal, `GRANT EXECUTE`, ACL de rede e a policy da OCI estão todos corretos, e cada um deles foi a causa de um erro anterior, já resolvido.

### O que é

A tenancy **não tem direito ao serviço**. Duas evidências independentes:

```bash
# 1. O mesmo 404 pelo OCI CLI, com usuário Administrator, fora do banco:
oci generative-ai-inference chat-result chat --region us-ashburn-1 \
    --compartment-id <compartment> \
    --serving-mode '{"servingType":"ON_DEMAND","modelId":"cohere.command-a-03-2025"}' \
    --chat-request '{"apiFormat":"COHERE","message":"ok","maxTokens":20}'
# -> 404 "Entity with key cohere.command-a-03-2025 not found"
#    Idem passando o OCID do modelo em vez do nome.

# 2. Todos os 51 limites do serviço estão zerados:
oci limits value list --service-name ai-generative --region us-ashburn-1 \
    --compartment-id <tenancy>
# -> grok-4-chat-tokens-per-minute-count      0
#    gemini-2-5-flash-chat-tokens-per-minute-count  0
#    ... 51 limites, todos 0
```

Os modelos aparecem em `list-models` como `ACTIVE` porque **listar** é operação de leitura do control plane. **Invocar** é serviço pago, e a conta não tem cota. O 404 é o jeito da OCI dizer "não autorizado ou não existe" sem revelar qual dos dois.

O Autonomous Database é Always Free, mas essa é outra coisa: o Generative AI não faz parte do Always Free e não tem camada gratuita.

### As duas saídas

| | Como | Custo | Esforço |
|---|---|---|---|
| **A. Upgrade da conta** | converter a tenancy para Pay As You Go no console da OCI | pago por token, centavos no volume do projeto | zero — o perfil `SUSRADAR` já está pronto e passa a responder sozinho |
| **B. Provedor externo** | chave do Google AI Studio (tem cota gratuita), OpenAI ou Anthropic | grátis no Gemini | rodar `03_provedor_google.sql` com a chave |

A opção B mantém tudo o mais igual: mesmas views, mesma camada semântica, mesma sintaxe `SELECT AI`. Só troca de onde vem o modelo. O perfil passa a se chamar `SUSRADAR_GOOGLE`.

Um ponto a decidir antes de escolher B: com provedor externo, o **esquema** das views e a **pergunta** saem para fora da Oracle. Os microdados de saúde não saem — o SQL é executado dentro do banco — mas nomes de tabela, nomes de coluna e os comentários vão no prompt. Com a opção A nada sai da OCI.

---

## Reproduzir do zero

```bash
# 1. a policy na OCI
oci iam policy create --compartment-id <tenancy> --name susradar-adb-genai \
  --statements '["Allow dynamic-group susradar-adb to use generative-ai-family in tenancy"]' \
  --description "Permite o ADB do SUS Radar 360 chamar o OCI Generative AI"

# 2. o de/para de região de saúde, do qual as views dependem
.venv/bin/python scripts/territorio.py

# 3. as views da Gold
.venv/bin/python scripts/db.py -u gold sql/03_gold/03_gld_regiao.sql

# 4. Select AI
.venv/bin/python scripts/db.py -u admin sql/04_select_ai/00_habilita.sql
.venv/bin/python scripts/db.py -u gold  sql/04_select_ai/01_camada_semantica.sql
.venv/bin/python scripts/db.py -u gold  sql/04_select_ai/02_perfil.sql

# 5. conferir que o modelo de dados responde
.venv/bin/python scripts/db.py -u gold  sql/04_select_ai/99_perguntas.sql
```

---

## Armadilhas encontradas

Cada uma custou um erro genérico que não dizia a causa.

**A ACL de rede é por usuário e o curinga não cobre subdomínio fundo.**
`*.oraclecloud.com` **não** cobriu `inference.generativeai.us-ashburn-1.oci.oraclecloud.com` — continuou dando `ORA-24247` até o host completo ser declarado. E declarar para `GOLD` não serve para `ADMIN`: a ACL é por *principal*.

**`ENABLE_PRINCIPAL_AUTH(username => 'GOLD')` não cria credencial no schema do GOLD.**
Depois de rodar, `dba_credentials` mostra `OCI$RESOURCE_PRINCIPAL` só em `ADMIN`. Não é problema — o perfil do `GOLD` referencia o nome e funciona —, mas quem for conferir procurando a credencial em `user_credentials` não vai achar e vai concluir errado.

**`provider_endpoint` não funciona com `provider: "oci"`.**
Tentar apontar o endpoint na mão faz o Oracle tratar a URL como URI de object storage: sem esquema dá `ORA-20006: Unsupported object store URI`, com `https://` a URL vira `oci://...`. Deixe o Oracle montar o endpoint a partir de `region`.

**Sem `region`, o padrão é `us-chicago-1`.**
Que esta tenancy não assina. Sempre declarar a região.

**Nome de modelo tem que existir para on-demand naquela região.**
`list-models` mostrando `ACTIVE` não garante que o nome sirva no `chat`. O erro é 404 com a mensagem `Entity with key <modelo> not found`, igual ao erro de falta de permissão.

**O `ALTER TABLE ... ADD` de `04_select_ai` e `03_gld_regiao.sql` precisa ser idempotente.**
Estes arquivos são reexecutados. O `ADD (semaforo ...)` está dentro de um bloco que engole `ORA-01430`.

---

## Próximos passos

1. **Decidir o provedor** — A ou B da tabela acima. Sem isso o Select AI não responde.
2. **Tela no APEX** — o protótipo prevê um campo de pergunta. `DBMS_CLOUD_AI.GENERATE` já devolve texto pronto para um item de página.
3. **Medir o critério de aceite** — "tempo de resposta < 15s em 90% das perguntas frequentes" só pode ser medido depois de (1).
4. **`ai_profile` no perfil do APEX** — para o app não precisar chamar `SET_PROFILE` em toda sessão.
