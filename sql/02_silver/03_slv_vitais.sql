-- SLV_OBITO e SLV_NASCIMENTO — SIM e SINASC tratados. Base do KPI 4.
--
-- Cuidado com as diferencas entre sistemas:
--   datas   SIH usa 'YYYYMMDD'; SIM e SINASC usam 'DDMMYYYY'
--   sexo    SIH usa 1=M/3=F; SIM usa 1=M/2=F/0=ignorado
--   idade   no SIM vem codificada em 3 digitos: 1o = unidade, 2 ultimos = valor
--           ('496' = 96 anos). Sem decodificar, um recem-nascido vira centenario.

CREATE TABLE slv_obito AS
SELECT
    TO_NUMBER(b.CODMUNRES)                  AS cod_munic_residencia,
    TO_DATE(b.DTOBITO, 'DDMMYYYY')          AS dt_obito,
    EXTRACT(YEAR  FROM TO_DATE(b.DTOBITO,'DDMMYYYY')) AS ano_obito,
    EXTRACT(MONTH FROM TO_DATE(b.DTOBITO,'DDMMYYYY')) AS mes_obito,
    b.CAUSABAS                              AS cid_causa_basica,
    SUBSTR(b.CAUSABAS, 1, 1)                AS cid_capitulo,
    CASE b.SEXO WHEN '1' THEN 'M' WHEN '2' THEN 'F' END AS sexo,
    -- IDADE do SIM: 1o digito = unidade (0=min 1=hora 2=dia 3=mes 4=ano 5=100+ano)
    CASE SUBSTR(b.IDADE, 1, 1)
      WHEN '5' THEN 100 + TO_NUMBER(SUBSTR(b.IDADE, 2, 2))
      WHEN '4' THEN TO_NUMBER(SUBSTR(b.IDADE, 2, 2))
      WHEN '3' THEN ROUND(TO_NUMBER(SUBSTR(b.IDADE, 2, 2)) / 12, 2)
      WHEN '2' THEN ROUND(TO_NUMBER(SUBSTR(b.IDADE, 2, 2)) / 365, 3)
      WHEN '1' THEN 0
      WHEN '0' THEN 0
    END                                     AS idade_anos,
    b.LOCOCOR                               AS cod_local_ocorrencia,
    l.descricao                             AS local_ocorrencia,
    b.RACACOR                               AS cod_raca_cor
  FROM bronze.brz_sim_do b
  LEFT JOIN slv_dom_local_obito l ON l.codigo = b.LOCOCOR
 WHERE b.DTOBITO IS NOT NULL
   AND REGEXP_LIKE(b.DTOBITO, '^\d{8}$');

CREATE INDEX ix_slv_obito_mun ON slv_obito (cod_munic_residencia);
CREATE INDEX ix_slv_obito_dt  ON slv_obito (dt_obito);
CREATE INDEX ix_slv_obito_cid ON slv_obito (cid_causa_basica);

CREATE TABLE slv_nascimento AS
SELECT
    TO_NUMBER(b.CODMUNRES)                  AS cod_munic_residencia,
    TO_NUMBER(b.CODMUNNASC)                 AS cod_munic_nascimento,
    TO_DATE(b.DTNASC, 'DDMMYYYY')           AS dt_nascimento,
    EXTRACT(YEAR  FROM TO_DATE(b.DTNASC,'DDMMYYYY')) AS ano_nascimento,
    EXTRACT(MONTH FROM TO_DATE(b.DTNASC,'DDMMYYYY')) AS mes_nascimento,
    TO_NUMBER(b.PESO)                       AS peso_gramas,
    CASE WHEN TO_NUMBER(b.PESO) < 2500 THEN 1 ELSE 0 END AS baixo_peso,
    b.GESTACAO                              AS cod_gestacao,
    g.descricao                             AS faixa_gestacao,
    CASE WHEN b.GESTACAO IN ('1','2','3','4') THEN 1 ELSE 0 END AS prematuro,
    b.CONSULTAS                             AS cod_consultas_prenatal,
    c.descricao                             AS consultas_prenatal,
    CASE WHEN b.CONSULTAS = '1' THEN 1 ELSE 0 END AS sem_prenatal,
    TO_NUMBER(b.APGAR5)                     AS apgar5,
    TO_NUMBER(b.IDADEMAE)                   AS idade_mae,
    CASE WHEN TO_NUMBER(b.IDADEMAE) < 20 THEN 1 ELSE 0 END AS mae_adolescente,
    CASE b.SEXO WHEN '1' THEN 'M' WHEN '2' THEN 'F' END AS sexo,
    b.PARTO                                 AS cod_tipo_parto
  FROM bronze.brz_sinasc_dn b
  LEFT JOIN slv_dom_gestacao g           ON g.codigo = b.GESTACAO
  LEFT JOIN slv_dom_consultas_prenatal c ON c.codigo = b.CONSULTAS
 WHERE b.DTNASC IS NOT NULL
   AND REGEXP_LIKE(b.DTNASC, '^\d{8}$');

CREATE INDEX ix_slv_nasc_mun ON slv_nascimento (cod_munic_residencia);
CREATE INDEX ix_slv_nasc_dt  ON slv_nascimento (dt_nascimento);
