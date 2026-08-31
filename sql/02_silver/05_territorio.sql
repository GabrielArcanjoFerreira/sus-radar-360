-- TERRITORIO — nome de municipio, coordenadas e o de/para municipio -> regiao de
-- saude. Cria SLV_REGIAO_SAUDE e completa SLV_MUNICIPIO.
--
-- A CARGA E FEITA POR scripts/territorio.py, nao por este arquivo. Ele registra a
-- estrutura no repositorio e guarda os grants e as consultas de conferencia:
--
--     .venv/bin/python scripts/territorio.py
--
-- Origem: Base Territorial do Ministerio da Saude, publicada a cada dois meses em
-- ftp.datasus.gov.br/territorio/tabelas/<AAAA>/. Nao e a mesma arvore dos
-- microdados (/dissemin/publicos/), o que explica por que ela passou batido na
-- ingestao da Sprint 2. Arquivos usados:
--     rl_municip_regsaud.csv   municipio -> regiao de saude
--     tb_regsaud.csv           codigo da regiao -> nome
--     tb_municip.csv           nome do municipio, UF, latitude, longitude
--
-- Isto encerra o unico bloqueio duro do projeto. Sem o de/para nao existia
-- VW_IPA_REGIAO, e sem ela caiam o mapa, o Top 5 em alerta e as perguntas do
-- Select AI sobre regioes.

-- Estrutura criada pelo script (nao executar daqui):
--
--   CREATE TABLE slv_regiao_saude (
--     cod_regiao_saude  VARCHAR2(5) PRIMARY KEY,   -- CO_REGSAUD do DATASUS
--     nome_regiao_saude VARCHAR2(60) NOT NULL,     -- sem o sufixo ' - UF' do original
--     uf                VARCHAR2(2),
--     ativa             CHAR(1)                    -- CO_STATUS S = regiao vigente
--   );
--
--   ALTER TABLE slv_municipio ADD (
--     cod_regiao_saude VARCHAR2(5),
--     nome_municipio   VARCHAR2(60),
--     latitude         NUMBER(10,6),
--     longitude        NUMBER(10,6)
--   );

-- A Gold monta VW_IPA_REGIAO em cima disto.
GRANT SELECT ON slv_regiao_saude TO gold;

-- ---------------------------------------------------------------------------
-- Conferencia (rodar como SILVER depois da carga)
-- ---------------------------------------------------------------------------

-- 645 de 645 municipios de SP mapeados em 62 regioes de saude, todos com nome.
-- O 646o registro e o codigo 350000, placeholder "Municipio Ignorado - Sp" que o
-- DATASUS usa quando a origem nao informa o municipio: nao e municipio, nao tem
-- regiao e nao tem nenhuma internacao.
SELECT COUNT(*) municipios, COUNT(nome_municipio) com_nome,
       COUNT(regiao_saude) com_regiao, COUNT(DISTINCT regiao_saude) regioes
  FROM slv_municipio WHERE uf = 'SP';

-- O teste que decide se o de/para serve: internacao sem regiao. Deu 0 de
-- 5.860.558, tanto pelo municipio de residencia quanto pelo de internacao.
SELECT COUNT(*) total,
       SUM(CASE WHEN mr.regiao_saude IS NULL THEN 1 ELSE 0 END) sem_regiao_residencia,
       SUM(CASE WHEN mi.regiao_saude IS NULL THEN 1 ELSE 0 END) sem_regiao_internacao
  FROM slv_internacao i
  LEFT JOIN slv_municipio mr ON mr.cod_municipio = i.cod_munic_residencia
  LEFT JOIN slv_municipio mi ON mi.cod_municipio = i.cod_munic_internacao;
