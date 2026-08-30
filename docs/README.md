# Documentação — SUS Radar 360

## Por onde começar

| Se você quer... | Leia |
|---|---|
| entender o projeto e o estado atual | [../README.md](../README.md) |
| entender como as peças se ligam | [arquitetura.md](arquitetura.md) |
| conectar o Power BI | [powerbi.md](powerbi.md) |
| saber o que cada coluna significa | [dicionario.md](dicionario.md) |
| refazer a carga do DATASUS | [ingestao.md](ingestao.md) |
| entender o cálculo do IPA | [gold.md](gold.md) |
| saber o que já quebrou e por quê | [problemas-conhecidos.md](problemas-conhecidos.md) |
| senhas e URLs de acesso | `acesso.md` — fora do git |

## Os documentos

**[arquitetura.md](arquitetura.md)** — fluxo de ponta a ponta, as três camadas, a infraestrutura OCI e as decisões de segurança. Começa aqui quem for pegar o projeto.

**[dicionario.md](dicionario.md)** — toda coluna de Bronze, Silver e Gold, com tipo, nulidade e significado. Gerado do banco por `scripts/gen_dicionario.py`; as descrições de negócio ficam no próprio script.

**[ingestao.md](ingestao.md)** — como reproduzir o download do DATASUS, quais competências foram escolhidas e por quê, e as decisões que divergem do deck da Sprint 1.

**[catalogo-bases.md](catalogo-bases.md)** — inventário dos 33 arquivos baixados: volume, período e colunas por base. Gerado por `scripts/catalogo.py`.

**[gold.md](gold.md)** — fórmulas do IPA e da permanência média, como foram derivadas da base de referência, limiares de risco e as ressalvas da medida.

**[powerbi.md](powerbi.md)** — passo a passo de conexão, com os erros já resolvidos. É o documento para circular com quem vai montar o painel.

**[problemas-conhecidos.md](problemas-conhecidos.md)** — defeitos dos arquivos do DATASUS, armadilhas do OCI CLI e do Oracle, e o bloqueio da região de saúde. Consulte antes de debugar algo do zero.

**`acesso.md`** — credenciais dos quatro usuários do banco, URLs do Database Actions e identificadores da OCI. **Não versionado.**

## O que é gerado e o que é escrito

Não edite à mão:

| Documento | Gerado por |
|---|---|
| `catalogo-bases.md` | `scripts/catalogo.py` |
| `dicionario.md` | `scripts/gen_dicionario.py` |
| `../sql/01_bronze/*.sql` | `scripts/gen_external_tables.py` |
| `../sql/01_bronze/uris.txt` | `scripts/upload_oci.sh` |

Os demais são escritos e mantidos à mão.

## Estado do projeto

| Camada | Situação |
|---|---|
| Ingestão | 33 arquivos, 9.045.693 registros |
| Object Storage | 35 objetos, 417 MB |
| Bronze | 5 tabelas, 9.045.693 linhas |
| Silver | 6 tabelas + 6 domínios, sem perda |
| Gold | 14.789 linhas |
| Região de saúde | **bloqueado** |
