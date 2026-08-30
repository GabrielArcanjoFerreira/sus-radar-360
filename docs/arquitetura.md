# Arquitetura

## Fluxo completo

```
FTP DATASUS ──► data/raw/*.dbc ──► data/processed/*.parquet ──► OCI Object Storage
                  download            DBC→DBF→Parquet              bulk-upload
                                                                        │
                    ┌───────────────────────────────────────────────────┘
                    ▼
            External Tables ──► BRONZE ──► SILVER ──► GOLD ──► Power BI / APEX / Select AI
            (DBMS_CLOUD)       materializada  tratada   painel
```

## Camadas

| Camada | Schema | O que é | Tabelas |
|---|---|---|---|
| Bronze | `BRONZE` | dado cru do DATASUS, tipos originais, códigos não traduzidos | 5 |
| Silver | `SILVER` | datas em `DATE`, idade em anos, códigos resolvidos, flags derivadas | 6 + 6 domínios |
| Gold | `GOLD` | fato do painel, agregado por `ano × mês × estabelecimento` | 2 |

O dicionário completo de colunas está em [dicionario.md](dicionario.md).

### Bronze — física, não externa

As External Tables existem e estão versionadas em `sql/01_bronze/`, mas as tabelas que a Silver consome são **físicas**, carregadas com `DBMS_CLOUD.COPY_DATA`.

Dois motivos. Primeiro, External Table relê o Object Storage a cada consulta — o deck promete resposta em menos de 15s no APEX, e isso não se sustenta relendo 417 MB de Parquet por clique. Segundo, o acesso do ADB ao Object Storage se mostrou instável nesta conta Always Free: `KUP-13016: HTTP-404` em arquivos que o `GET_OBJECT` lia inteiros, com o padrão invertendo entre chamadas seguidas.

### Silver — tratamento

O que a Silver resolve, que o dado cru não entrega:

- **Datas.** O SIH usa `AAAAMMDD`; SIM e SINASC usam `DDMMAAAA`. Tudo vira `DATE`.
- **Idade.** No SIH, `IDADE` só faz sentido junto de `COD_IDADE` (2=dias, 3=meses, 4=anos, 5=100+anos). No SIM ela vem codificada em 3 dígitos, com o primeiro indicando a unidade — `'496'` são 96 anos. Sem decodificar, um recém-nascido vira centenário.
- **Sexo.** O SIH usa `1=M, 3=F`; o SIM usa `1=M, 2=F`. Domínios diferentes para o mesmo conceito.
- **Códigos.** Especialidade, caráter da internação, complexidade, gestação, pré-natal e local do óbito viram texto, por tabelas `slv_dom_*`.

### Gold — o painel

`gld_painel_assistencial` reproduz a estrutura da base que alimentava o Power BI. Grão: `ano × mês × estabelecimento`.

```
ipa_percentual    = total_dias_permanencia / (capacidade_leitos × 30) × 100
permanencia_media = total_dias_permanencia / internacoes
```

Fórmulas validadas contra a base de referência, 1281 de 1281 linhas com erro zero. Detalhes e ressalvas em [gold.md](gold.md).

Carregada por `prc_carga_painel_assistencial`, não por view — a agregação varre 5,8 milhões de linhas e leva ~5s, o que numa view seria pago a cada clique de filtro.

## Infraestrutura OCI

| Recurso | Valor |
|---|---|
| Tenancy | `greatminds2026` |
| Região | `us-ashburn-1` (home region) |
| Compartment | `sus-radar-360` |
| Namespace | `idnxdejel4kp` |
| Bucket | `datasus-raw` — `NoPublicAccess`, 35 objetos, 417 MB |
| Autonomous DB | `SUS Radar 360` / `SUSRADAR` — Oracle 19c, workload DW, Always Free |
| Dynamic group | `susradar-adb` |
| Policy | `susradar-adb-objectstorage` |

### Como o banco lê o bucket

Por **resource principal** (`OCI$RESOURCE_PRINCIPAL`), não por chave API.

A credencial por chave API falhou com `ORA-20401` em todos os formatos testados — corpo do `.pem` com e sem cabeçalho, com e sem quebras de linha — e o Auth Token falhou igual, em URI nativa e Swift. A mesma chave funcionava pelo CLI, e a policy `Allow group Administrators to manage all-resources in tenancy` existia. Resource principal resolveu, e é melhor prática de qualquer forma: nenhuma chave privada dentro do banco.

O `susradar-adb` casa o OCID do ADB; a policy dá a ele `read buckets` e `read objects` no compartment.

### Estrutura no bucket

```
datasus-raw/
  processed/sihsus/RDSP2406..RDSP2605.parquet    24 arquivos
  processed/cnes/{LT,ST}SP2607.parquet            2
  processed/sim/DOSP2021..2024.parquet            4
  processed/sinasc/DNSP2020..2022.parquet         3
  processed/_manifesto.csv  _catalogo.csv         metadado da carga
```

Bucket é `NoPublicAccess` por obrigação: são microdados de saúde. O acesso do banco se dá por credencial, nunca por URL pública.

## Segurança

- Um usuário por camada (`BRONZE`, `SILVER`, `GOLD`), com `GRANT SELECT` apenas na camada anterior. `ADMIN` não é usado para dados.
- `GOLD` é o usuário do Power BI — só enxerga a Gold, e o painel consome uma view.
- Wallet, chave `.pem` e `docs/acesso.md` estão no `.gitignore`.
- `scripts/db.py` mascara `IDENTIFIED BY` e `password =>` antes de imprimir qualquer comando.

## Consumo

| Ferramenta | Aponta para |
|---|---|
| Power BI | `GOLD.VW_PAINEL_ASSISTENCIAL` — ver [powerbi.md](powerbi.md) |
| APEX | `.../ords/apex` no mesmo ADB |
| Select AI | pendente — precisa da `VW_IPA_REGIAO`, bloqueada pela região de saúde |
