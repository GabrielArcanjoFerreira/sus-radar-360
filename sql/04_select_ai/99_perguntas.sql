-- AS SEIS PERGUNTAS DO CONTRATO — SQL de referencia.
-- Rodar como GOLD.
--
-- Para que serve: separar dois problemas que sempre se confundem. Se o Select AI
-- responde errado, ou o modelo de dados nao suporta a pergunta, ou o modelo de
-- linguagem gerou SQL ruim. Este arquivo responde as seis perguntas na mao. Se
-- todas retornam resultado coerente, o modelo de dados esta certo e qualquer erro
-- do Select AI e do lado do LLM ou da camada semantica.
--
-- Serve tambem como gabarito: rode a mesma pergunta no Select AI e compare.

-- ---------------------------------------------------------------------------
-- 1. Quais regioes de SP estao em alerta vermelho neste mes?
--    (o SQL exato que o prototipo da Sprint 1 mostra como gerado)
-- ---------------------------------------------------------------------------
SELECT regiao_saude, ipa, semaforo FROM VW_IPA_REGIAO
WHERE semaforo = 'VERMELHO' ORDER BY ipa DESC;

-- ---------------------------------------------------------------------------
-- 2. Quais municipios tiveram maior aumento de internacoes no ultimo trimestre?
-- ---------------------------------------------------------------------------
WITH janela AS (
  SELECT MAX(competencia) fim FROM vw_painel_municipio_mensal
),
tri AS (
  SELECT m.nome_municipio, m.regiao_saude,
         SUM(CASE WHEN m.competencia > TO_NUMBER(TO_CHAR(
               ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -3), 'YYYYMM'))
                  THEN m.internacoes ELSE 0 END) AS trimestre_atual,
         SUM(CASE WHEN m.competencia <= TO_NUMBER(TO_CHAR(
               ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -3), 'YYYYMM'))
               AND  m.competencia >  TO_NUMBER(TO_CHAR(
               ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
                  THEN m.internacoes ELSE 0 END) AS trimestre_anterior
    FROM vw_painel_municipio_mensal m CROSS JOIN janela j
   GROUP BY m.nome_municipio, m.regiao_saude
)
SELECT nome_municipio, regiao_saude, trimestre_anterior, trimestre_atual,
       trimestre_atual - trimestre_anterior AS variacao,
       ROUND(100 * (trimestre_atual - trimestre_anterior)
             / NULLIF(trimestre_anterior, 0), 1) AS variacao_pct
  FROM tri
 WHERE trimestre_anterior >= 500
 ORDER BY variacao_pct DESC NULLS LAST
 FETCH FIRST 10 ROWS ONLY;

-- ---------------------------------------------------------------------------
-- 3. Quais hospitais tem permanencia media acima da media estadual?
-- ---------------------------------------------------------------------------
SELECT cod_cnes, nome_municipio, regiao_saude,
       SUM(internacoes) internacoes,
       ROUND(SUM(dias_permanencia) / SUM(internacoes), 2) permanencia_media,
       MAX(permanencia_media_estadual) media_estadual
  FROM vw_painel_hospital
 GROUP BY cod_cnes, nome_municipio, regiao_saude
HAVING SUM(internacoes) >= 1000
   AND SUM(dias_permanencia) / SUM(internacoes) > MAX(permanencia_media_estadual)
 ORDER BY permanencia_media DESC
 FETCH FIRST 10 ROWS ONLY;

-- ---------------------------------------------------------------------------
-- 4. Compare internacoes e leitos disponiveis por regiao de saude.
-- ---------------------------------------------------------------------------
SELECT regiao_saude, internacoes, leitos,
       ROUND(internacoes / NULLIF(leitos, 0), 1) AS internacoes_por_leito_ano,
       permanencia_media, ipa, semaforo
  FROM vw_ipa_regiao
 ORDER BY internacoes_por_leito_ano DESC NULLS LAST
 FETCH FIRST 10 ROWS ONLY;

-- ---------------------------------------------------------------------------
-- 5. Onde a pressao por internacoes respiratorias esta crescendo mais rapido?
-- ---------------------------------------------------------------------------
WITH janela AS (
  SELECT MAX(competencia) fim FROM vw_morbidade_regiao_mensal
),
resp AS (
  SELECT r.regiao_saude,
         SUM(CASE WHEN r.competencia > TO_NUMBER(TO_CHAR(
               ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
                  THEN r.internacoes ELSE 0 END) AS semestre_atual,
         SUM(CASE WHEN r.competencia <= TO_NUMBER(TO_CHAR(
               ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
               AND  r.competencia >  TO_NUMBER(TO_CHAR(
               ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -12), 'YYYYMM'))
                  THEN r.internacoes ELSE 0 END) AS semestre_anterior
    FROM vw_morbidade_regiao_mensal r CROSS JOIN janela j
   WHERE r.cid_capitulo = 'J'
   GROUP BY r.regiao_saude
)
SELECT regiao_saude, semestre_anterior, semestre_atual,
       ROUND(100 * (semestre_atual - semestre_anterior)
             / NULLIF(semestre_anterior, 0), 1) AS crescimento_pct
  FROM resp
 WHERE semestre_anterior >= 300
 ORDER BY crescimento_pct DESC NULLS LAST
 FETCH FIRST 10 ROWS ONLY;

-- ---------------------------------------------------------------------------
-- 6. Quais regioes pioraram entre o ultimo semestre e o atual?
-- ---------------------------------------------------------------------------
WITH janela AS (
  SELECT MAX(competencia) fim FROM vw_painel_regiao_mensal
),
sem AS (
  SELECT p.regiao_saude,
         ROUND(SUM(CASE WHEN p.competencia > TO_NUMBER(TO_CHAR(
                 ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
                    THEN p.dias_permanencia_com_leito END)
               / NULLIF(SUM(CASE WHEN p.competencia > TO_NUMBER(TO_CHAR(
                 ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
                    THEN p.leitos END) * 30, 0) * 100, 2) AS ipa_atual,
         ROUND(SUM(CASE WHEN p.competencia <= TO_NUMBER(TO_CHAR(
                 ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
                   AND  p.competencia >  TO_NUMBER(TO_CHAR(
                 ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -12), 'YYYYMM'))
                    THEN p.dias_permanencia_com_leito END)
               / NULLIF(SUM(CASE WHEN p.competencia <= TO_NUMBER(TO_CHAR(
                 ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -6), 'YYYYMM'))
                   AND  p.competencia >  TO_NUMBER(TO_CHAR(
                 ADD_MONTHS(TO_DATE(TO_CHAR(j.fim), 'YYYYMM'), -12), 'YYYYMM'))
                    THEN p.leitos END) * 30, 0) * 100, 2) AS ipa_anterior
    FROM vw_painel_regiao_mensal p CROSS JOIN janela j
   GROUP BY p.regiao_saude
)
SELECT regiao_saude, ipa_anterior, ipa_atual,
       ROUND(ipa_atual - ipa_anterior, 2) AS variacao_pontos
  FROM sem
 WHERE ipa_atual > ipa_anterior
 ORDER BY variacao_pontos DESC
 FETCH FIRST 10 ROWS ONLY;

-- ---------------------------------------------------------------------------
-- Bonus, so possivel porque a ingestao usou microdado: quais regioes mais
-- mandam o proprio morador se internar fora.
-- ---------------------------------------------------------------------------
SELECT regiao_residencia,
       SUM(internacoes) total,
       SUM(CASE WHEN saiu_da_regiao = 'S' THEN internacoes ELSE 0 END) saiu,
       ROUND(100 * SUM(CASE WHEN saiu_da_regiao = 'S' THEN internacoes ELSE 0 END)
             / NULLIF(SUM(internacoes), 0), 1) AS evasao_pct
  FROM vw_fluxo_regiao
 GROUP BY regiao_residencia
HAVING SUM(internacoes) >= 5000
 ORDER BY evasao_pct DESC
 FETCH FIRST 10 ROWS ONLY;
