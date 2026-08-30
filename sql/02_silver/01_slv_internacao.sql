-- SLV_INTERNACAO — SIH/SUS RD tratado. 1 linha = 1 internacao (AIH).
-- Base do KPI 1 (Demanda Hospitalar) e do fluxo intermunicipal que alimenta o IPA.
--
-- Transformacoes aplicadas:
--   datas    'YYYYMMDD' texto -> DATE
--   idade    normalizada para anos usando COD_IDADE (2=dias 3=meses 4=anos 5=100+anos)
--   sexo     SIH usa 1=M e 3=F (nao 2=F como o SIM) -> 'M'/'F'
--   codigos  ESPEC, CAR_INT, COMPLEX resolvidos pelas tabelas de dominio
--   flags    MORTE e UTI viram 0/1 explicitos

CREATE TABLE slv_internacao AS
SELECT
    b.N_AIH                                              AS num_aih,
    TO_NUMBER(b.MUNIC_RES)                               AS cod_munic_residencia,
    TO_NUMBER(b.MUNIC_MOV)                               AS cod_munic_internacao,
    b.CNES                                               AS cod_cnes,
    TO_DATE(b.DT_INTER, 'YYYYMMDD')                      AS dt_internacao,
    TO_DATE(b.DT_SAIDA, 'YYYYMMDD')                      AS dt_saida,
    TO_NUMBER(b.ANO_CMPT)                                AS ano_competencia,
    TO_NUMBER(b.MES_CMPT)                                AS mes_competencia,
    b.DIAS_PERM                                          AS dias_permanencia,
    b.DIAG_PRINC                                         AS cid_principal,
    SUBSTR(b.DIAG_PRINC, 1, 1)                           AS cid_capitulo,
    b.DIAG_SECUN                                         AS cid_secundario,
    b.PROC_REA                                           AS cod_procedimento,
    b.ESPEC                                              AS cod_especialidade,
    e.descricao                                          AS especialidade,
    b.CAR_INT                                            AS cod_carater,
    c.descricao                                          AS carater_internacao,
    b.COMPLEX                                            AS cod_complexidade,
    x.descricao                                          AS complexidade,
    CASE b.SEXO WHEN '1' THEN 'M' WHEN '3' THEN 'F' WHEN '2' THEN 'F' END AS sexo,
    -- COD_IDADE define a unidade de IDADE; sem isso um bebe de 5 dias vira 5 anos
    CASE b.COD_IDADE
      WHEN '4' THEN b.IDADE
      WHEN '5' THEN 100 + b.IDADE
      WHEN '3' THEN ROUND(b.IDADE / 12, 2)
      WHEN '2' THEN ROUND(b.IDADE / 365, 2)
      WHEN '1' THEN 0
    END                                                  AS idade_anos,
    CASE WHEN b.MORTE = 1 THEN 1 ELSE 0 END              AS obito,
    CASE WHEN NVL(b.UTI_MES_TO, 0) > 0 THEN 1 ELSE 0 END AS usou_uti,
    NVL(b.UTI_MES_TO, 0)                                 AS diarias_uti,
    b.VAL_TOT                                            AS valor_total,
    b.VAL_SH                                             AS valor_servicos_hospitalares,
    b.VAL_SP                                             AS valor_servicos_profissionais,
    -- o par que sustenta o IPA: quem mora fora do municipio onde internou
    CASE WHEN b.MUNIC_RES <> b.MUNIC_MOV THEN 1 ELSE 0 END AS internou_fora_do_municipio
  FROM bronze.brz_sih_rd b
  LEFT JOIN slv_dom_sih_espec   e ON e.codigo = b.ESPEC
  LEFT JOIN slv_dom_sih_car_int c ON c.codigo = b.CAR_INT
  LEFT JOIN slv_dom_complexidade x ON x.codigo = b.COMPLEX
 WHERE b.DT_INTER IS NOT NULL;

ALTER TABLE slv_internacao ADD CONSTRAINT pk_slv_internacao PRIMARY KEY (num_aih) RELY DISABLE NOVALIDATE;
CREATE INDEX ix_slv_int_munres  ON slv_internacao (cod_munic_residencia);
CREATE INDEX ix_slv_int_cnes    ON slv_internacao (cod_cnes);
CREATE INDEX ix_slv_int_dt      ON slv_internacao (dt_internacao);
CREATE INDEX ix_slv_int_cid     ON slv_internacao (cid_principal);
