-- SLV_MUNICIPIO — dimensao territorial.
--
-- BLOQUEIO CONHECIDO: a coluna regiao_saude fica NULL.
-- Todo o painel agrega por regiao de saude, e NENHUMA base do DATASUS baixada
-- traz esse agrupamento de forma utilizavel:
--   * o SIH so tem codigo IBGE de municipio;
--   * o REGSAUDE do CNES e texto livre — 56% em branco, 291 valores distintos,
--     e o proprio municipio 355030 (Sao Paulo) aparece com '', '0000', '001',
--     '01', '010', '0100', '013'. So 58 dos 645 municipios tem valor consistente.
-- Preencher exige a tabela oficial de regioes de saude de SP (Transferencia de
-- Arquivos, Modalidade Documentacao). Sem ela nao existe VW_IPA_REGIAO.

CREATE TABLE slv_municipio (
  cod_municipio   NUMBER(6) PRIMARY KEY,
  uf              VARCHAR2(2),
  regiao_saude    VARCHAR2(60),     -- PENDENTE: carregar da tabela oficial
  populacao       NUMBER            -- PENDENTE: IBGE
);

-- Semente com todos os municipios que aparecem nos dados
INSERT INTO slv_municipio (cod_municipio, uf)
SELECT cod, CASE WHEN SUBSTR(TO_CHAR(cod),1,2) = '35' THEN 'SP' ELSE NULL END
  FROM (
    SELECT DISTINCT cod_munic_residencia AS cod FROM slv_internacao WHERE cod_munic_residencia IS NOT NULL
    UNION SELECT DISTINCT cod_munic_internacao FROM slv_internacao WHERE cod_munic_internacao IS NOT NULL
    UNION SELECT DISTINCT cod_municipio        FROM slv_estabelecimento
    UNION SELECT DISTINCT cod_munic_residencia FROM slv_obito
    UNION SELECT DISTINCT cod_munic_residencia FROM slv_nascimento
  );
COMMIT;
