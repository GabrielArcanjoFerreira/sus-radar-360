# Camada Gold — painel assistencial

Alimenta o painel do Power BI. Reproduz a estrutura da base de referência `painel_assistencial_ipa_2015_2020.csv`.

## Objetos

| Objeto | O que é |
|---|---|
| `gld_painel_assistencial` | tabela fato, grão `ano × mês × estabelecimento` |
| `gld_faixa_risco` | dimensão dos limiares de risco (o Power BI usa como "Faixas Risco") |
| `prc_carga_painel_assistencial` | rotina que carrega a Gold a partir da Silver |
| `vw_painel_assistencial` | view no formato exato da base de referência |

## Como recarregar

```sql
DECLARE n NUMBER; BEGIN prc_carga_painel_assistencial(NULL, n); DBMS_OUTPUT.PUT_LINE(n); END;
/
-- ou só de um ano em diante
DECLARE n NUMBER; BEGIN prc_carga_painel_assistencial(2025, n); END;
/
```

Sem `p_ano_min` faz recarga completa (`TRUNCATE`); com ele, apaga e recarrega dali para frente.

## Fórmulas

Validadas contra a base de referência, **1281 de 1281 linhas com erro zero**:

```
permanencia_media = total_dias_permanencia / internacoes
ipa_percentual    = total_dias_permanencia / (capacidade_leitos × 30) × 100
```

O IPA é uma **taxa de ocupação de leito** no mês de 30 dias.

## Limiares de risco

A base de referência só contém `ESTÁVEL` (até 41,25) e `MÉDIO RISCO` (60,67 a 66,74), então o ponto de corte exato entre elas e os limites superiores **não são observáveis nos dados**. Adotadas as faixas clássicas de ocupação hospitalar:

| Nível | IPA |
|---|---|
| ESTÁVEL | 0 – 49,99 |
| MÉDIO RISCO | 50 – 74,99 |
| CRÍTICO | 75 – 99,99 |
| COLAPSO | 100 ou mais |

Para mudar, altere **só** a tabela `gld_faixa_risco` — a rotina lê os limiares de lá.

## Eixo do tempo

Usa `ano_competencia` e `mes_competencia`, **não** `dt_internacao`. A AIH é faturada por competência, mas `dt_internacao` guarda a admissão real — em 2,66% dos casos anterior à janela carregada, chegando a 2008 (crônicos). Agrupar por `dt_internacao` criaria uma cauda falsa de 217 meses no gráfico de evolução.

## Ressalva sobre o IPA

384 de 14.658 linhas (2,6%) dão IPA acima de 100%, impossível para taxa de ocupação. São 86 estabelecimentos de longa permanência (13,3 dias de média contra 5,2). Causas: o CNES é snapshot único de 2026-07 aplicado a 24 meses de SIH, e o IPA divide todas as internações por todos os leitos sem casar especialidade. Detalhes e opções de tratamento em `sql/gold/02_prc_carga_painel.sql`.

## Divergências encontradas no dashboard atual

Conferido contra a base de referência com filtro `Estado = AM`:

| Card | Dashboard | Base | Situação |
|---|---|---|---|
| Internações | 43 | 43 | correto |
| Permanência Média | 5,49 | 5,49 | correto |
| Maior IPA | 286 | **2,86%** | a medida multiplica por 100 um valor que já é percentual |
| Nível de Risco | CRÍTICO / COLAPSO | 27 de 27 linhas são **ESTÁVEL** | o card não respeita o filtro |
