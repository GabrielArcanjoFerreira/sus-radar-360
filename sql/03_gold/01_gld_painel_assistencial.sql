-- CAMADA GOLD — GLD_PAINEL_ASSISTENCIAL
-- Tabela que alimenta o painel do Power BI. Grao: ano x mes x estabelecimento.
--
-- Formulas validadas contra a base de referencia (1281/1281 linhas, erro zero):
--   permanencia_media = total_dias_permanencia / internacoes
--   ipa_percentual    = total_dias_permanencia / (capacidade_leitos * 30) * 100
--                       ou seja, taxa de ocupacao de leito no mes (30 dias).
--
-- ATENCAO ao eixo do tempo: usa ano/mes_competencia, NAO dt_internacao. A AIH e
-- faturada por competencia mas dt_internacao guarda a admissao real, que em 2,66%
-- dos casos e anterior a janela carregada (cronicos, ate 2008). Agrupar por
-- dt_internacao criaria uma cauda falsa de 217 meses no grafico de evolucao.

CREATE TABLE gld_faixa_risco (
  nivel   VARCHAR2(20) PRIMARY KEY,
  ordem   NUMBER(1),
  ipa_min NUMBER(10,2),
  ipa_max NUMBER(10,2),
  cor     VARCHAR2(7)
);

-- Limiares: a base de referencia so contem ESTAVEL (ate 41,25) e MEDIO RISCO
-- (60,67 a 66,74), entao o corte exato entre elas e os limites superiores nao
-- sao observaveis. Adotadas as faixas classicas de ocupacao hospitalar.
-- Se o time definir outros pontos de corte, alterar SO esta tabela — a rotina le daqui.
INSERT ALL
  INTO gld_faixa_risco VALUES ('ESTAVEL',           1,   0,  49.99, '#2E7D32')
  INTO gld_faixa_risco VALUES ('MEDIO RISCO',       2,  50,  74.99, '#F9A825')
  INTO gld_faixa_risco VALUES ('CRITICO',           3,  75,  99.99, '#EF6C00')
  INTO gld_faixa_risco VALUES ('COLAPSO',           4, 100, 999999, '#C62828')
SELECT * FROM dual;
COMMIT;

CREATE TABLE gld_painel_assistencial (
  ano                              NUMBER(4)   NOT NULL,
  mes                              NUMBER(2)   NOT NULL,
  sigla_uf                         VARCHAR2(2),
  id_municipio_estabelecimento_aih NUMBER(7),
  id_estabelecimento_cnes          NUMBER(10)  NOT NULL,
  internacoes                      NUMBER,
  total_dias_permanencia           NUMBER,
  permanencia_media                NUMBER(10,2),
  capacidade_leitos                NUMBER,
  custo_total                      NUMBER(14,2),
  ipa_percentual                   NUMBER(10,2),
  risco_assistencial               VARCHAR2(20),
  CONSTRAINT pk_gld_painel PRIMARY KEY (ano, mes, id_estabelecimento_cnes)
);

CREATE INDEX ix_gld_painel_uf   ON gld_painel_assistencial (sigla_uf, ano, mes);
CREATE INDEX ix_gld_painel_risco ON gld_painel_assistencial (risco_assistencial);
