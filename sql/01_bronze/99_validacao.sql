-- Validacao da camada Bronze.
-- Rode DEPOIS de criar as External Tables. A criacao nao valida a URI — o erro
-- so aparece na primeira consulta.

-- 1. Volume: tem que bater com data/catalogo.csv
--    Valores esperados da carga de 2026-08-29:
--      BRZ_SIH_RD      5.860.558   (24 competencias, 2024-06 a 2026-05)
--      BRZ_CNES_LT         8.327   (2026-07)
--      BRZ_CNES_ST       115.148   (2026-07)
--      BRZ_SIM_DO      1.471.591   (2021 a 2024)
--      BRZ_SINASC_DN   1.590.069   (2020 a 2022)
--    Total: 9.045.693 registros
SELECT 'BRZ_SIH_RD'    AS tabela, COUNT(*) AS registros FROM BRZ_SIH_RD
UNION ALL SELECT 'BRZ_CNES_LT',   COUNT(*) FROM BRZ_CNES_LT
UNION ALL SELECT 'BRZ_CNES_ST',   COUNT(*) FROM BRZ_CNES_ST
UNION ALL SELECT 'BRZ_SIM_DO',    COUNT(*) FROM BRZ_SIM_DO
UNION ALL SELECT 'BRZ_SINASC_DN', COUNT(*) FROM BRZ_SINASC_DN;

-- 2. Cobertura temporal do SIH: 24 competencias contiguas, sem buraco
SELECT ANO_CMPT, MES_CMPT, COUNT(*) AS internacoes
  FROM BRZ_SIH_RD GROUP BY ANO_CMPT, MES_CMPT ORDER BY 1, 2;

-- 3. A coluna que so existe de 2025-03 em diante precisa vir NULL antes disso.
--    Se vier NULL em TODAS as competencias, o column_list nao casou com o parquet.
SELECT ANO_CMPT, MES_CMPT,
       COUNT(*) AS linhas,
       COUNT(FONTE_ORC) AS com_fonte_orc
  FROM BRZ_SIH_RD GROUP BY ANO_CMPT, MES_CMPT ORDER BY 1, 2;

-- 4. Sanidade de dominio do SIH (esperado para SP)
SELECT COUNT(DISTINCT MUNIC_RES) AS munic_residencia,   -- ~1.370 (inclui outros estados)
       COUNT(DISTINCT MUNIC_MOV) AS munic_internacao,   -- ~400
       COUNT(DISTINCT CNES)      AS hospitais,          -- ~900 no periodo todo
       MIN(DT_INTER) AS primeira, MAX(DT_INTER) AS ultima,
       ROUND(AVG(DIAS_PERM), 2)  AS perm_media,         -- ~5
       ROUND(100 * AVG(MORTE), 2) AS letalidade_pct     -- ~4,8
  FROM BRZ_SIH_RD;

-- 5. CNES: tem que cobrir os 645 municipios de SP
SELECT COUNT(DISTINCT CODUFMUN) AS municipios,
       COUNT(DISTINCT CNES)     AS estabelecimentos,
       COUNT(DISTINCT REGSAUDE) AS regioes_saude
  FROM BRZ_CNES_ST;

-- 6. Erros de carga nao aparecem no SELECT — estao aqui.
--    logfile_table e badfile_table apontam para o detalhe.
SELECT id, type, status, start_time, rows_loaded, logfile_table, badfile_table
  FROM user_load_operations ORDER BY start_time DESC FETCH FIRST 20 ROWS ONLY;
