-- BRZ_CNES_LT — CNES LT — leitos por estabelecimento e tipo
-- Gerado por scripts/gen_external_tables.py. Nao editar a mao.
-- Fonte: 1 arquivo(s), LTSP2607 a LTSP2607
-- Colunas: 28
--
-- Substitua <REGIAO>, <NAMESPACE> e <BUCKET> antes de rodar (veja sql/external_tables/uris.txt).

BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => 'BRZ_CNES_LT',
    credential_name => 'OCI$RESOURCE_PRINCIPAL',
    file_uri_list   => 'https://objectstorage.<REGIAO>.oraclecloud.com/n/<NAMESPACE>/b/<BUCKET>/o/processed/cnes/LT*.parquet',
    format          => JSON_OBJECT('type' VALUE 'parquet'),
    column_list     => '
      CNES     VARCHAR2(10 CHAR),
      CODUFMUN VARCHAR2(10 CHAR),
      REGSAUDE VARCHAR2(10 CHAR),
      MICR_REG VARCHAR2(10 CHAR),
      DISTRSAN VARCHAR2(10 CHAR),
      DISTRADM VARCHAR2(10 CHAR),
      TPGESTAO VARCHAR2(10 CHAR),
      PF_PJ    VARCHAR2(10 CHAR),
      CPF_CNPJ VARCHAR2(17 CHAR),
      NIV_DEP  VARCHAR2(10 CHAR),
      CNPJ_MAN VARCHAR2(17 CHAR),
      ESFERA_A VARCHAR2(10 CHAR),
      ATIVIDAD VARCHAR2(10 CHAR),
      RETENCAO VARCHAR2(10 CHAR),
      NATUREZA VARCHAR2(10 CHAR),
      CLIENTEL VARCHAR2(10 CHAR),
      TP_UNID  VARCHAR2(10 CHAR),
      TURNO_AT VARCHAR2(10 CHAR),
      NIV_HIER VARCHAR2(10 CHAR),
      TERCEIRO VARCHAR2(10 CHAR),
      TP_LEITO VARCHAR2(10 CHAR),
      CODLEITO VARCHAR2(10 CHAR),
      QT_EXIST NUMBER(19),
      QT_CONTR NUMBER(19),
      QT_SUS   NUMBER(19),
      QT_NSUS  NUMBER(19),
      COMPETEN VARCHAR2(10 CHAR),
      NAT_JUR  VARCHAR2(10 CHAR)
    ');
END;
/

-- A criacao NAO valida a URI: so falha na primeira consulta. Confira sempre.
SELECT COUNT(*) AS registros FROM BRZ_CNES_LT;
