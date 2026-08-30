-- Rotina de carga da Gold a partir da Silver.
-- Recarga completa (a Silver e carga unica); trocar para MERGE se virar incremental.
--
--   EXEC prc_carga_painel_assistencial;
--   EXEC prc_carga_painel_assistencial(p_ano_min => 2025);

CREATE OR REPLACE PROCEDURE prc_carga_painel_assistencial (
  p_ano_min IN NUMBER DEFAULT NULL,
  p_linhas  OUT NUMBER
) AS
BEGIN
  IF p_ano_min IS NULL THEN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE gld_painel_assistencial';
  ELSE
    DELETE FROM gld_painel_assistencial WHERE ano >= p_ano_min;
  END IF;

  INSERT INTO gld_painel_assistencial (
    ano, mes, sigla_uf, id_municipio_estabelecimento_aih, id_estabelecimento_cnes,
    internacoes, total_dias_permanencia, permanencia_media, capacidade_leitos,
    custo_total, ipa_percentual, risco_assistencial)
  WITH leitos AS (
    -- capacidade por estabelecimento; o CNES e snapshot, entao vale para todo o periodo
    SELECT cod_cnes, SUM(qtd_existente) AS capacidade
      FROM slv_leito GROUP BY cod_cnes
  ),
  base AS (
    SELECT i.ano_competencia AS ano,
           i.mes_competencia AS mes,
           -- UF derivada do codigo IBGE do municipio (2 primeiros digitos)
           CASE SUBSTR(TO_CHAR(i.cod_munic_internacao), 1, 2)
             WHEN '35' THEN 'SP' WHEN '33' THEN 'RJ' WHEN '31' THEN 'MG'
             WHEN '41' THEN 'PR' WHEN '43' THEN 'RS' WHEN '42' THEN 'SC'
             WHEN '29' THEN 'BA' WHEN '26' THEN 'PE' WHEN '23' THEN 'CE'
             WHEN '52' THEN 'GO' WHEN '53' THEN 'DF' WHEN '15' THEN 'PA'
             WHEN '13' THEN 'AM' WHEN '21' THEN 'MA' WHEN '32' THEN 'ES'
             WHEN '51' THEN 'MT' WHEN '50' THEN 'MS' WHEN '25' THEN 'PB'
             WHEN '24' THEN 'RN' WHEN '27' THEN 'AL' WHEN '28' THEN 'SE'
             WHEN '22' THEN 'PI' WHEN '17' THEN 'TO' WHEN '11' THEN 'RO'
             WHEN '12' THEN 'AC' WHEN '14' THEN 'RR' WHEN '16' THEN 'AP'
           END AS sigla_uf,
           i.cod_munic_internacao AS id_municipio,
           TO_NUMBER(i.cod_cnes)  AS cnes,
           COUNT(*)                     AS internacoes,
           SUM(i.dias_permanencia)      AS total_dias,
           SUM(i.valor_total)           AS custo_total
      FROM slv_internacao i
     WHERE i.cod_cnes IS NOT NULL
       AND (p_ano_min IS NULL OR i.ano_competencia >= p_ano_min)
     GROUP BY i.ano_competencia, i.mes_competencia,
              SUBSTR(TO_CHAR(i.cod_munic_internacao), 1, 2),
              i.cod_munic_internacao, i.cod_cnes
  ),
  calc AS (
    SELECT b.*, l.capacidade,
           CASE WHEN b.internacoes > 0
                THEN ROUND(b.total_dias / b.internacoes, 2) END AS perm_media,
           -- sem leito cadastrado no CNES nao ha denominador: IPA fica NULL,
           -- nunca zero (zero significaria ocupacao nula, que e afirmacao falsa)
           CASE WHEN NVL(l.capacidade, 0) > 0
                THEN ROUND(b.total_dias / (l.capacidade * 30) * 100, 2) END AS ipa
      FROM base b LEFT JOIN leitos l ON l.cod_cnes = LPAD(TO_CHAR(b.cnes), 7, '0')
  )
  SELECT c.ano, c.mes, c.sigla_uf, c.id_municipio, c.cnes,
         c.internacoes, c.total_dias, c.perm_media, c.capacidade,
         c.custo_total, c.ipa,
         (SELECT f.nivel FROM gld_faixa_risco f
           WHERE c.ipa BETWEEN f.ipa_min AND f.ipa_max)
    FROM calc c;

  p_linhas := SQL%ROWCOUNT;
  COMMIT;
END;
/

-- View no formato exato da base de referencia, para o Power BI consumir
CREATE OR REPLACE VIEW vw_painel_assistencial AS
SELECT ano, mes, sigla_uf,
       id_municipio_estabelecimento_aih,
       id_estabelecimento_cnes,
       internacoes, total_dias_permanencia, permanencia_media,
       capacidade_leitos, custo_total, ipa_percentual, risco_assistencial
  FROM gld_painel_assistencial;

-- -----------------------------------------------------------------------------
-- RESSALVA METODOLOGICA sobre o IPA (medida, nao bug da rotina)
--
-- 384 de 14.658 linhas (2,6%) dao IPA acima de 100%, o que e impossivel para uma
-- taxa de ocupacao. Sao 86 estabelecimentos com permanencia media de 13,3 dias
-- contra 5,2 dos demais — hospitais de longa permanencia (tipos CNES 05 e 07).
--
-- Duas causas, ambas do denominador:
--   1. O CNES e um snapshot unico (2026-07) aplicado a 24 meses de SIH. Leito
--      fechado ou recadastrado depois nao aparece na competencia certa.
--   2. O IPA divide TODAS as internacoes por TODOS os leitos, sem casar
--      especialidade. Um psiquiatrico com poucos leitos gerais cadastrados e
--      internacoes de 30 dias estoura a conta.
--
-- Como tratar, em ordem de esforco:
--   a) filtrar ipa_percentual <= 100 nos rankings do painel (o "Top 10 CNES por
--      IPA" hoje mostraria justamente esses artefatos no topo);
--   b) baixar o CNES LT por competencia e casar leito com mes da AIH;
--   c) casar TP_LEITO do CNES com ESPEC da AIH.
-- Decisao do time. A rotina calcula fielmente a formula da base de referencia.
