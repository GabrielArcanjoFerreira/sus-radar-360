-- Validacao da camada Silver.

-- 1. Volume vs Bronze: a Silver descarta linhas com data invalida.
--    Perda acima de ~0,1% merece investigacao.
SELECT 'slv_internacao'  AS tabela, COUNT(*) AS linhas FROM slv_internacao
UNION ALL SELECT 'slv_leito',           COUNT(*) FROM slv_leito
UNION ALL SELECT 'slv_estabelecimento', COUNT(*) FROM slv_estabelecimento
UNION ALL SELECT 'slv_obito',           COUNT(*) FROM slv_obito
UNION ALL SELECT 'slv_nascimento',      COUNT(*) FROM slv_nascimento
UNION ALL SELECT 'slv_municipio',       COUNT(*) FROM slv_municipio;

-- 2. As datas converteram? Faixa tem que bater com as competencias baixadas.
SELECT MIN(dt_internacao) AS de, MAX(dt_internacao) AS ate,
       COUNT(DISTINCT TO_CHAR(dt_internacao,'YYYY-MM')) AS competencias
  FROM slv_internacao;

-- 3. Decodificacao funcionou? Nenhum destes pode ser 100% nulo.
SELECT COUNT(*) AS total,
       COUNT(sexo)               AS com_sexo,
       COUNT(idade_anos)         AS com_idade,
       COUNT(especialidade)      AS com_especialidade,
       COUNT(carater_internacao) AS com_carater,
       COUNT(complexidade)       AS com_complexidade
  FROM slv_internacao;

-- 4. Idade normalizada: sem isso um bebe de 5 dias viraria 5 anos.
WITH f AS (
  SELECT CASE WHEN idade_anos < 1  THEN 'menor de 1 ano'
              WHEN idade_anos < 15 THEN '1 a 14'
              WHEN idade_anos < 60 THEN '15 a 59'
              ELSE '60 ou mais' END AS faixa
    FROM slv_internacao)
SELECT faixa, COUNT(*) AS internacoes FROM f GROUP BY faixa ORDER BY 2 DESC;

-- 4b. ATENCAO AO EIXO DO TEMPO. DT_INTER e a data real de admissao e pode ser
-- muito anterior a competencia em que a AIH foi faturada: 2,66% das linhas tem
-- DT_INTER antes de 2024-06, chegando a 2008 (pacientes cronicos, permanencia
-- media de 30 dias). Serie mensal do painel deve usar ano/mes_competencia;
-- usar dt_internacao cria uma cauda falsa de 217 meses.
SELECT COUNT(*) AS fora_da_janela
  FROM slv_internacao WHERE dt_internacao < DATE '2024-06-01';

-- 5. Fluxo intermunicipal — o insumo central do IPA
SELECT ROUND(100 * AVG(internou_fora_do_municipio), 2) AS pct_fora_do_municipio
  FROM slv_internacao;

-- 6. Sanidade epidemiologica
SELECT ROUND(100*AVG(baixo_peso),2) AS pct_baixo_peso,      -- esperado ~9%
       ROUND(100*AVG(prematuro),2)  AS pct_prematuro,        -- esperado ~11%
       ROUND(100*AVG(mae_adolescente),2) AS pct_mae_adolescente
  FROM slv_nascimento;

-- 7. O bloqueio conhecido: regiao de saude ainda nao mapeada
SELECT COUNT(*) AS municipios, COUNT(regiao_saude) AS com_regiao_saude
  FROM slv_municipio;
