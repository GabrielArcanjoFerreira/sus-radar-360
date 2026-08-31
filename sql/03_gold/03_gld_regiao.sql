-- CAMADA GOLD — visao por REGIAO DE SAUDE
--
-- Estas sao as views que o Select AI e o painel consomem. Todas dependem de
-- SILVER.SLV_MUNICIPIO.REGIAO_SAUDE, preenchida por scripts/regiao_saude.py.
--
-- Contrato fechado no prototipo da Sprint 1:
--     VW_IPA_REGIAO (regiao_saude, ipa, semaforo)
--     semaforo IN ('VERDE','AMARELO','VERMELHO')
--
-- O IPA aqui e o mesmo da GLD_PAINEL_ASSISTENCIAL — taxa de ocupacao de leito,
-- dias de permanencia sobre leitos-dia disponiveis — so que somado ao nivel de
-- regiao antes de dividir. Nao e a media dos IPA dos hospitais: regiao grande e
-- regiao pequena entrariam com o mesmo peso.

-- ---------------------------------------------------------------------------
-- Semaforo: o prototipo tem 3 cores, a GLD_FAIXA_RISCO tem 4 niveis.
-- Em vez de duplicar pontos de corte, o semaforo vira coluna da mesma tabela.
-- Mudou o limiar? Muda so aqui, e as duas escalas acompanham.
-- ---------------------------------------------------------------------------
-- idempotente: o arquivo inteiro precisa poder ser reexecutado
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE gld_faixa_risco ADD (semaforo VARCHAR2(10))';
EXCEPTION
  WHEN OTHERS THEN IF SQLCODE != -1430 THEN RAISE; END IF;  -- -1430 = coluna ja existe
END;
/

UPDATE gld_faixa_risco
   SET semaforo = CASE ordem WHEN 1 THEN 'VERDE'
                             WHEN 2 THEN 'AMARELO'
                             ELSE 'VERMELHO' END;
COMMIT;

-- ---------------------------------------------------------------------------
-- VW_PAINEL_REGIAO_MENSAL — fato mensal por regiao de saude.
-- Grao: regiao x ano x mes. ~62 regioes x 24 competencias.
-- Regiao = a do municipio do ESTABELECIMENTO, nao a do paciente: leito, equipe e
-- pressao de ocupacao ficam onde o hospital esta. O olhar pelo paciente esta em
-- VW_FLUXO_REGIAO.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_painel_regiao_mensal AS
WITH agg AS (
  SELECT m.cod_regiao_saude,
         m.regiao_saude,
         p.ano,
         p.mes,
         p.ano * 100 + p.mes                              AS competencia,
         COUNT(DISTINCT p.id_estabelecimento_cnes)         AS hospitais,
         COUNT(DISTINCT p.id_municipio_estabelecimento_aih) AS municipios,
         SUM(p.internacoes)                                AS internacoes,
         SUM(p.total_dias_permanencia)                     AS dias_permanencia,
         -- mesmo numerador do IPA: so hospital com leito cadastrado
         SUM(CASE WHEN p.capacidade_leitos > 0
                  THEN p.total_dias_permanencia END)        AS dias_permanencia_com_leito,
         SUM(p.capacidade_leitos)                          AS leitos,
         SUM(p.custo_total)                                AS custo_total,
         ROUND(SUM(p.total_dias_permanencia)
               / NULLIF(SUM(p.internacoes), 0), 2)         AS permanencia_media,
         -- so entram no numerador os hospitais que tem leito cadastrado no CNES;
         -- somar dias de quem nao tem denominador inflaria a ocupacao da regiao
         ROUND(SUM(CASE WHEN p.capacidade_leitos > 0 THEN p.total_dias_permanencia END)
               / NULLIF(SUM(p.capacidade_leitos) * 30, 0) * 100, 2) AS ipa,
         SUM(CASE WHEN NVL(p.capacidade_leitos, 0) = 0
                  THEN p.internacoes ELSE 0 END)           AS internacoes_sem_leito_cnes
    FROM gld_painel_assistencial p
    JOIN silver.slv_municipio m
      ON m.cod_municipio = p.id_municipio_estabelecimento_aih
   WHERE m.regiao_saude IS NOT NULL
   GROUP BY m.cod_regiao_saude, m.regiao_saude, p.ano, p.mes
)
SELECT a.cod_regiao_saude, a.regiao_saude, a.ano, a.mes, a.competencia,
       a.internacoes, a.dias_permanencia, a.dias_permanencia_com_leito, a.permanencia_media,
       a.leitos, a.hospitais, a.municipios, a.custo_total,
       a.ipa, f.nivel AS risco_assistencial, f.semaforo,
       a.internacoes_sem_leito_cnes
  FROM agg a
  LEFT JOIN gld_faixa_risco f ON a.ipa BETWEEN f.ipa_min AND f.ipa_max;

-- ---------------------------------------------------------------------------
-- VW_IPA_REGIAO — o contrato. Uma linha por regiao, ultimos 12 meses de dado.
-- A janela e movel: acompanha a competencia mais recente carregada, entao a view
-- nao envelhece sozinha quando chegar mais SIH.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ipa_regiao AS
WITH janela AS (
  SELECT MAX(ano * 100 + mes) AS fim,
         -- 12 competencias contando a ultima: recua 11 meses no calendario
         TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(MAX(ano * 100 + mes)), 'YYYYMM'), -11),
                           'YYYYMM')) AS inicio
    FROM gld_painel_assistencial
),
agg AS (
  SELECT r.cod_regiao_saude, r.regiao_saude,
         SUM(r.internacoes)                                AS internacoes,
         SUM(r.dias_permanencia)                           AS dias_permanencia,
         SUM(r.custo_total)                                AS custo_total,
         ROUND(SUM(r.dias_permanencia)
               / NULLIF(SUM(r.internacoes), 0), 2)         AS permanencia_media,
         ROUND(AVG(r.leitos))                              AS leitos,
         MAX(r.hospitais)                                  AS hospitais,
         MAX(r.municipios)                                 AS municipios,
         ROUND(SUM(r.dias_permanencia_com_leito)
               / NULLIF(SUM(r.leitos) * 30, 0) * 100, 2)   AS ipa,
         ROUND(SUM(r.internacoes) / 365, 1)                AS internacoes_dia
    FROM vw_painel_regiao_mensal r, janela j
   WHERE r.competencia BETWEEN j.inicio AND j.fim
   GROUP BY r.cod_regiao_saude, r.regiao_saude
)
SELECT a.regiao_saude,
       a.ipa,
       f.semaforo,
       f.nivel AS risco_assistencial,
       a.cod_regiao_saude,
       a.internacoes, a.internacoes_dia, a.permanencia_media,
       a.leitos, a.hospitais, a.municipios, a.custo_total,
       j.inicio AS competencia_inicio, j.fim AS competencia_fim,
       RANK() OVER (ORDER BY a.ipa DESC NULLS LAST) AS posicao_ranking
  FROM agg a
  CROSS JOIN janela j
  LEFT JOIN gld_faixa_risco f ON a.ipa BETWEEN f.ipa_min AND f.ipa_max;

-- ---------------------------------------------------------------------------
-- VW_PAINEL_HOSPITAL — GLD_PAINEL_ASSISTENCIAL com regiao e a media estadual
-- ao lado, para a pergunta "quais hospitais tem permanencia acima da media de SP".
-- Sem a coluna de comparacao na propria linha, isso vira subconsulta correlata e
-- o modelo de linguagem erra com frequencia.
--
-- Nao ha NOME de estabelecimento: o grupo ST do CNES nao traz razao social nem
-- nome fantasia. O hospital sai identificado pelo codigo CNES.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_painel_hospital AS
SELECT p.id_estabelecimento_cnes                AS cod_cnes,
       m.regiao_saude,
       m.cod_regiao_saude,
       p.id_municipio_estabelecimento_aih       AS cod_municipio,
       m.nome_municipio,
       p.sigla_uf,
       p.ano, p.mes, p.ano * 100 + p.mes        AS competencia,
       p.internacoes,
       p.total_dias_permanencia                 AS dias_permanencia,
       p.permanencia_media,
       p.capacidade_leitos                      AS leitos,
       p.custo_total,
       p.ipa_percentual                         AS ipa,
       p.risco_assistencial,
       f.semaforo,
       -- media estadual PONDERADA (soma dos dias / soma das internacoes). Media
       -- das medias dos hospitais daria peso igual a hospital de 10 e de 10.000 AIH.
       ROUND(SUM(p.total_dias_permanencia) OVER ()
             / NULLIF(SUM(p.internacoes) OVER (), 0), 2)             AS permanencia_media_estadual,
       ROUND(SUM(p.total_dias_permanencia) OVER (PARTITION BY p.ano, p.mes)
             / NULLIF(SUM(p.internacoes) OVER (PARTITION BY p.ano, p.mes), 0), 2)
                                                                     AS permanencia_media_estadual_mes
  FROM gld_painel_assistencial p
  LEFT JOIN silver.slv_municipio m
    ON m.cod_municipio = p.id_municipio_estabelecimento_aih
  LEFT JOIN gld_faixa_risco f
    ON p.risco_assistencial = f.nivel;

-- ---------------------------------------------------------------------------
-- VW_PAINEL_MUNICIPIO_MENSAL — fato mensal por municipio do estabelecimento.
-- Grao: municipio x ano x mes. Existe para as perguntas de variacao ("quais
-- municipios cresceram mais no ultimo trimestre") sem obrigar o modelo a agregar
-- a view de hospital na mao.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_painel_municipio_mensal AS
WITH agg AS (
  SELECT p.id_municipio_estabelecimento_aih      AS cod_municipio,
         m.nome_municipio,
         m.regiao_saude,
         m.cod_regiao_saude,
         m.latitude, m.longitude,
         p.ano, p.mes, p.ano * 100 + p.mes       AS competencia,
         COUNT(DISTINCT p.id_estabelecimento_cnes) AS hospitais,
         SUM(p.internacoes)                      AS internacoes,
         SUM(p.total_dias_permanencia)           AS dias_permanencia,
         SUM(p.capacidade_leitos)                AS leitos,
         SUM(p.custo_total)                      AS custo_total,
         ROUND(SUM(p.total_dias_permanencia)
               / NULLIF(SUM(p.internacoes), 0), 2) AS permanencia_media,
         ROUND(SUM(CASE WHEN p.capacidade_leitos > 0 THEN p.total_dias_permanencia END)
               / NULLIF(SUM(p.capacidade_leitos) * 30, 0) * 100, 2) AS ipa
    FROM gld_painel_assistencial p
    LEFT JOIN silver.slv_municipio m
      ON m.cod_municipio = p.id_municipio_estabelecimento_aih
   GROUP BY p.id_municipio_estabelecimento_aih, m.nome_municipio, m.regiao_saude,
            m.cod_regiao_saude, m.latitude, m.longitude, p.ano, p.mes
)
SELECT a.*, f.nivel AS risco_assistencial, f.semaforo
  FROM agg a
  LEFT JOIN gld_faixa_risco f ON a.ipa BETWEEN f.ipa_min AND f.ipa_max;

-- ---------------------------------------------------------------------------
-- VW_MORBIDADE_REGIAO_MENSAL — internacoes por capitulo do CID-10.
-- Grao: regiao x ano x mes x capitulo. E a view das perguntas por doenca —
-- respiratorio e o capitulo J.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_morbidade_regiao_mensal AS
SELECT m.cod_regiao_saude,
       m.regiao_saude,
       i.ano_competencia                        AS ano,
       i.mes_competencia                        AS mes,
       i.ano_competencia * 100 + i.mes_competencia AS competencia,
       i.cid_capitulo,
       CASE i.cid_capitulo
         WHEN 'A' THEN 'Doencas infecciosas e parasitarias'
         WHEN 'B' THEN 'Doencas infecciosas e parasitarias'
         WHEN 'C' THEN 'Neoplasias (cancer)'
         WHEN 'D' THEN 'Neoplasias e doencas do sangue'
         WHEN 'E' THEN 'Doencas endocrinas, nutricionais e metabolicas'
         WHEN 'F' THEN 'Transtornos mentais e comportamentais'
         WHEN 'G' THEN 'Doencas do sistema nervoso'
         WHEN 'H' THEN 'Doencas do olho e do ouvido'
         WHEN 'I' THEN 'Doencas do aparelho circulatorio'
         WHEN 'J' THEN 'Doencas do aparelho respiratorio'
         WHEN 'K' THEN 'Doencas do aparelho digestivo'
         WHEN 'L' THEN 'Doencas da pele'
         WHEN 'M' THEN 'Doencas osteomusculares'
         WHEN 'N' THEN 'Doencas do aparelho geniturinario'
         WHEN 'O' THEN 'Gravidez, parto e puerperio'
         WHEN 'P' THEN 'Afeccoes originadas no periodo perinatal'
         WHEN 'Q' THEN 'Malformacoes congenitas'
         WHEN 'R' THEN 'Sintomas e achados anormais'
         WHEN 'S' THEN 'Lesoes e envenenamentos'
         WHEN 'T' THEN 'Lesoes e envenenamentos'
         WHEN 'U' THEN 'Codigos de uso especial'
         WHEN 'Z' THEN 'Contatos com servicos de saude'
         ELSE 'Nao classificado'
       END                                      AS grupo_doenca,
       COUNT(*)                                 AS internacoes,
       SUM(i.dias_permanencia)                  AS dias_permanencia,
       ROUND(AVG(i.dias_permanencia), 2)        AS permanencia_media,
       SUM(i.obito)                             AS obitos_hospitalares,
       ROUND(100 * SUM(i.obito) / COUNT(*), 2)  AS taxa_mortalidade_pct,
       SUM(i.usou_uti)                          AS internacoes_com_uti,
       SUM(i.valor_total)                       AS custo_total
  FROM silver.slv_internacao i
  JOIN silver.slv_municipio m
    ON m.cod_municipio = i.cod_munic_internacao
 WHERE m.regiao_saude IS NOT NULL
 GROUP BY m.cod_regiao_saude, m.regiao_saude, i.ano_competencia, i.mes_competencia,
          i.cid_capitulo;

-- ---------------------------------------------------------------------------
-- VW_FLUXO_REGIAO — para onde o paciente vai se internar.
-- Grao: regiao de residencia x regiao de internacao, na janela toda.
-- Linha em que as duas regioes diferem e paciente que saiu da propria regiao —
-- o indicio mais direto de falta de leito local. Este cruzamento so existe
-- porque a ingestao usou microdado: TABNET agregado nao tem o par de municipios.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_fluxo_regiao AS
SELECT mr.regiao_saude                          AS regiao_residencia,
       mi.regiao_saude                          AS regiao_internacao,
       CASE WHEN mr.cod_regiao_saude = mi.cod_regiao_saude
            THEN 'N' ELSE 'S' END               AS saiu_da_regiao,
       COUNT(*)                                 AS internacoes,
       SUM(i.dias_permanencia)                  AS dias_permanencia,
       SUM(i.obito)                             AS obitos_hospitalares,
       SUM(i.valor_total)                       AS custo_total
  FROM silver.slv_internacao i
  JOIN silver.slv_municipio mr ON mr.cod_municipio = i.cod_munic_residencia
  JOIN silver.slv_municipio mi ON mi.cod_municipio = i.cod_munic_internacao
 WHERE mr.regiao_saude IS NOT NULL
   AND mi.regiao_saude IS NOT NULL
 GROUP BY mr.regiao_saude, mi.regiao_saude, mr.cod_regiao_saude, mi.cod_regiao_saude;

-- ---------------------------------------------------------------------------
-- VW_VITAL_REGIAO_ANUAL — obitos (SIM) e nascidos vivos (SINASC) por regiao.
--
-- ATENCAO: a janela NAO e a mesma do SIH. SIM cobre 2021-2024 e SINASC 2020-2022,
-- porque essas bases atrasam 1 a 2 anos. Nao da para cruzar ano a ano com as
-- internacoes (2024-06 a 2026-05) — os anos simplesmente nao se encontram.
-- Grao: regiao x ano, pelo municipio de RESIDENCIA da pessoa.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_vital_regiao_anual AS
WITH obitos AS (
  SELECT m.cod_regiao_saude, m.regiao_saude, o.ano_obito AS ano,
         COUNT(*) AS obitos,
         SUM(CASE WHEN o.cid_capitulo = 'J' THEN 1 ELSE 0 END) AS obitos_respiratorios,
         SUM(CASE WHEN o.cid_capitulo = 'I' THEN 1 ELSE 0 END) AS obitos_circulatorios,
         SUM(CASE WHEN o.idade_anos < 1 THEN 1 ELSE 0 END)     AS obitos_menores_1_ano
    FROM silver.slv_obito o
    JOIN silver.slv_municipio m ON m.cod_municipio = o.cod_munic_residencia
   WHERE m.regiao_saude IS NOT NULL
   GROUP BY m.cod_regiao_saude, m.regiao_saude, o.ano_obito
),
nascimentos AS (
  SELECT m.cod_regiao_saude, m.regiao_saude, n.ano_nascimento AS ano,
         COUNT(*) AS nascidos_vivos,
         SUM(n.baixo_peso)      AS nascidos_baixo_peso,
         SUM(n.prematuro)       AS nascidos_prematuros,
         SUM(n.sem_prenatal)    AS nascidos_sem_prenatal,
         SUM(n.mae_adolescente) AS filhos_de_mae_adolescente
    FROM silver.slv_nascimento n
    JOIN silver.slv_municipio m ON m.cod_municipio = n.cod_munic_residencia
   WHERE m.regiao_saude IS NOT NULL
   GROUP BY m.cod_regiao_saude, m.regiao_saude, n.ano_nascimento
)
SELECT NVL(o.cod_regiao_saude, n.cod_regiao_saude) AS cod_regiao_saude,
       NVL(o.regiao_saude, n.regiao_saude)         AS regiao_saude,
       NVL(o.ano, n.ano)                           AS ano,
       o.obitos, o.obitos_respiratorios, o.obitos_circulatorios,
       o.obitos_menores_1_ano,
       n.nascidos_vivos, n.nascidos_baixo_peso, n.nascidos_prematuros,
       n.nascidos_sem_prenatal, n.filhos_de_mae_adolescente
  FROM obitos o
  FULL OUTER JOIN nascimentos n
    ON n.cod_regiao_saude = o.cod_regiao_saude AND n.ano = o.ano;
