-- SLV_LEITO e SLV_ESTABELECIMENTO — CNES tratado. Base do KPI 2 (Capacidade).
-- Snapshot da rede, nao serie temporal: cada competencia substitui a anterior.

CREATE TABLE slv_leito AS
SELECT
    b.CNES                       AS cod_cnes,
    TO_NUMBER(b.CODUFMUN)        AS cod_municipio,
    b.TP_LEITO                   AS cod_tipo_leito,
    b.CODLEITO                   AS cod_leito,
    b.QT_EXIST                   AS qtd_existente,
    b.QT_SUS                     AS qtd_sus,
    b.QT_CONTR                   AS qtd_contratado,
    TO_NUMBER(SUBSTR(b.COMPETEN,1,4)) AS ano_competencia,
    TO_NUMBER(SUBSTR(b.COMPETEN,5,2)) AS mes_competencia
  FROM bronze.brz_cnes_lt b;

CREATE INDEX ix_slv_leito_cnes ON slv_leito (cod_cnes);
CREATE INDEX ix_slv_leito_mun  ON slv_leito (cod_municipio);

CREATE TABLE slv_estabelecimento AS
SELECT
    b.CNES                       AS cod_cnes,
    TO_NUMBER(b.CODUFMUN)        AS cod_municipio,
    b.TP_UNID                    AS cod_tipo_unidade,
    b.TPGESTAO                   AS cod_gestao,
    b.NAT_JUR                    AS cod_natureza_juridica,
    b.NIV_HIER                   AS cod_nivel_hierarquia,
    CASE WHEN b.VINC_SUS = '1' THEN 1 ELSE 0 END AS atende_sus,
    -- REGSAUDE do CNES NAO e confiavel: 56% em branco e sem padronizacao
    -- (o municipio 355030 traz '', '0000', '001', '01', '010', '0100'...).
    -- Mantido apenas como evidencia; nao usar para agregar por regiao.
    b.REGSAUDE                   AS regsaude_cnes_nao_confiavel
  FROM bronze.brz_cnes_st b;

CREATE INDEX ix_slv_estab_cnes ON slv_estabelecimento (cod_cnes);
CREATE INDEX ix_slv_estab_mun  ON slv_estabelecimento (cod_municipio);

-- Leitos consolidados por municipio — denominador direto do IPA
CREATE OR REPLACE VIEW vw_slv_leitos_municipio AS
SELECT cod_municipio,
       SUM(qtd_existente) AS leitos_existentes,
       SUM(qtd_sus)       AS leitos_sus,
       COUNT(DISTINCT cod_cnes) AS estabelecimentos
  FROM slv_leito
 GROUP BY cod_municipio;
