-- CAMADA SEMANTICA — comentarios de tabela e coluna das views expostas ao Select AI.
-- Rodar como GOLD. Reexecutavel.
--
-- Isto nao e documentacao decorativa. O perfil do Select AI e criado com
-- comments => 'true', entao COMMENT ON e literalmente o texto que vai no prompt
-- do modelo junto com o DDL. Uma coluna sem comentario e uma coluna que o modelo
-- vai adivinhar. E onde se ganha ou se perde a acuracia do NL -> SQL.
--
-- Regras de escrita:
--   1. Dizer a unidade (percentual, dias, reais) e o grao.
--   2. Dizer os valores possiveis quando o dominio e fechado.
--   3. Dizer os sinonimos que o gestor usa ("alerta vermelho", "sobrecarga").
--   4. Avisar do que NAO da para responder — evita resposta confiante e errada.

-- ===========================================================================
-- VW_IPA_REGIAO — o contrato do prototipo
-- ===========================================================================
COMMENT ON TABLE vw_ipa_regiao IS
'Ranking de pressao assistencial das 62 regioes de saude do estado de Sao Paulo nos ultimos 12 meses de dado disponivel. UMA LINHA POR REGIAO DE SAUDE, ja agregada. E a tabela principal para qualquer pergunta sobre quais regioes estao em alerta, criticas, sobrecarregadas, no vermelho, ou no topo do ranking de risco. Use esta view e nao as outras quando a pergunta nao mencionar um mes ou um periodo especifico.';

COMMENT ON COLUMN vw_ipa_regiao.regiao_saude IS
'Nome da regiao de saude, por exemplo Franco da Rocha, Sorocaba, Sao Jose do Rio Preto, Alto do Tiete. Regiao de saude e o agrupamento oficial de municipios usado pelo SUS para planejar a rede. Sao Paulo tem 62.';
COMMENT ON COLUMN vw_ipa_regiao.ipa IS
'IPA, Indice de Pressao Assistencial, em percentual de 0 a 100. E a taxa de ocupacao dos leitos da regiao: dias de internacao consumidos dividido pelos leitos-dia disponiveis. Quanto maior, mais pressionada a rede. Sinonimos que o gestor usa: pressao, sobrecarga, ocupacao, lotacao.';
COMMENT ON COLUMN vw_ipa_regiao.semaforo IS
'Classificacao de risco em tres cores. Valores possiveis, exatamente estes: VERDE, AMARELO, VERMELHO. VERMELHO significa IPA de 75 por cento ou mais e e o que o gestor chama de alerta vermelho, regiao critica ou regiao em alerta. AMARELO e IPA de 50 a 74,99. VERDE e ate 49,99.';
COMMENT ON COLUMN vw_ipa_regiao.risco_assistencial IS
'Mesma classificacao do semaforo em quatro niveis. Valores possiveis: ESTAVEL, MEDIO RISCO, CRITICO, COLAPSO. ESTAVEL equivale a VERDE, MEDIO RISCO a AMARELO, CRITICO e COLAPSO a VERMELHO.';
COMMENT ON COLUMN vw_ipa_regiao.cod_regiao_saude IS
'Codigo oficial de 5 digitos da regiao de saude no DATASUS. As de Sao Paulo comecam com 35.';
COMMENT ON COLUMN vw_ipa_regiao.internacoes IS
'Total de internacoes do SUS na regiao nos 12 meses da janela. Uma internacao e uma AIH, a autorizacao pela qual o hospital e pago.';
COMMENT ON COLUMN vw_ipa_regiao.internacoes_dia IS
'Media diaria de internacoes na regiao. E o total dividido por 365.';
COMMENT ON COLUMN vw_ipa_regiao.permanencia_media IS
'Media de dias que o paciente fica internado na regiao. A media do estado fica proxima de 5 dias.';
COMMENT ON COLUMN vw_ipa_regiao.leitos IS
'Media mensal de leitos cadastrados no CNES nos hospitais da regiao. E o denominador do IPA.';
COMMENT ON COLUMN vw_ipa_regiao.hospitais IS
'Quantidade de hospitais com internacao pelo SUS na regiao.';
COMMENT ON COLUMN vw_ipa_regiao.municipios IS
'Quantidade de municipios da regiao que tem hospital com internacao pelo SUS. NAO e o total de municipios da regiao.';
COMMENT ON COLUMN vw_ipa_regiao.custo_total IS
'Valor total pago pelo SUS pelas internacoes da regiao na janela, em reais.';
COMMENT ON COLUMN vw_ipa_regiao.competencia_inicio IS
'Primeiro mes da janela de 12 meses, no formato numerico AAAAMM.';
COMMENT ON COLUMN vw_ipa_regiao.competencia_fim IS
'Ultimo mes da janela de 12 meses, no formato numerico AAAAMM. E o mes mais recente com dado carregado.';
COMMENT ON COLUMN vw_ipa_regiao.posicao_ranking IS
'Posicao da regiao no ranking de IPA. A posicao 1 e a regiao mais pressionada do estado. Use para perguntas de tipo top 5 ou top 10 regioes criticas.';

-- ===========================================================================
-- VW_PAINEL_REGIAO_MENSAL — a mesma coisa, mes a mes
-- ===========================================================================
COMMENT ON TABLE vw_painel_regiao_mensal IS
'Serie mensal de pressao assistencial por regiao de saude de Sao Paulo. UMA LINHA POR REGIAO E POR MES. Use esta view para tendencia, evolucao, crescimento, comparacao entre periodos, sazonalidade, ou quando a pergunta citar um mes, trimestre, semestre ou ano. Para o retrato consolidado dos ultimos 12 meses use VW_IPA_REGIAO.';

COMMENT ON COLUMN vw_painel_regiao_mensal.regiao_saude IS 'Nome da regiao de saude.';
COMMENT ON COLUMN vw_painel_regiao_mensal.cod_regiao_saude IS 'Codigo de 5 digitos da regiao de saude no DATASUS.';
COMMENT ON COLUMN vw_painel_regiao_mensal.ano IS 'Ano da competencia, com 4 digitos.';
COMMENT ON COLUMN vw_painel_regiao_mensal.mes IS 'Mes da competencia, de 1 a 12.';
COMMENT ON COLUMN vw_painel_regiao_mensal.competencia IS
'Mes de referencia no formato numerico AAAAMM, por exemplo 202605. Ordenar por esta coluna coloca a serie em ordem cronologica. E a competencia de faturamento da AIH, nao a data de admissao do paciente.';
COMMENT ON COLUMN vw_painel_regiao_mensal.internacoes IS 'Internacoes do SUS na regiao no mes.';
COMMENT ON COLUMN vw_painel_regiao_mensal.dias_permanencia IS 'Soma dos dias de internacao no mes.';
COMMENT ON COLUMN vw_painel_regiao_mensal.dias_permanencia_com_leito IS
'Numerador do IPA: soma dos dias de internacao apenas dos hospitais que tem leito cadastrado no CNES. Coluna tecnica, raramente e o que o gestor quer.';
COMMENT ON COLUMN vw_painel_regiao_mensal.permanencia_media IS 'Media de dias de internacao por paciente no mes.';
COMMENT ON COLUMN vw_painel_regiao_mensal.leitos IS 'Leitos cadastrados no CNES na regiao. Denominador do IPA.';
COMMENT ON COLUMN vw_painel_regiao_mensal.hospitais IS 'Hospitais com internacao no mes.';
COMMENT ON COLUMN vw_painel_regiao_mensal.municipios IS 'Municipios com hospital com internacao no mes.';
COMMENT ON COLUMN vw_painel_regiao_mensal.custo_total IS 'Valor pago pelo SUS no mes, em reais.';
COMMENT ON COLUMN vw_painel_regiao_mensal.ipa IS
'IPA do mes, taxa de ocupacao de leito em percentual de 0 a 100.';
COMMENT ON COLUMN vw_painel_regiao_mensal.risco_assistencial IS
'Nivel de risco do mes. Valores: ESTAVEL, MEDIO RISCO, CRITICO, COLAPSO.';
COMMENT ON COLUMN vw_painel_regiao_mensal.semaforo IS
'Cor do mes. Valores: VERDE, AMARELO, VERMELHO. VERMELHO e alerta vermelho.';
COMMENT ON COLUMN vw_painel_regiao_mensal.internacoes_sem_leito_cnes IS
'Internacoes de hospitais sem leito cadastrado no CNES. Ficam de fora do calculo do IPA. Serve para medir quanto da regiao o indicador nao cobre.';

-- ===========================================================================
-- VW_PAINEL_MUNICIPIO_MENSAL
-- ===========================================================================
COMMENT ON TABLE vw_painel_municipio_mensal IS
'Serie mensal de internacoes e ocupacao por MUNICIPIO do estado de Sao Paulo. UMA LINHA POR MUNICIPIO E POR MES. Use para perguntas sobre municipios: quais cresceram mais, quais tem mais internacoes, qual a evolucao de um municipio. O municipio e o do HOSPITAL onde a internacao aconteceu, nao o de moradia do paciente. Para o cruzamento entre onde o paciente mora e onde ele se interna use VW_FLUXO_REGIAO.';

COMMENT ON COLUMN vw_painel_municipio_mensal.cod_municipio IS 'Codigo IBGE de 6 digitos do municipio. Os de Sao Paulo comecam com 35.';
COMMENT ON COLUMN vw_painel_municipio_mensal.nome_municipio IS
'Nome do municipio, por exemplo Sao Paulo, Campinas, Ribeirao Preto. Sempre mostre o nome e nao o codigo nas respostas.';
COMMENT ON COLUMN vw_painel_municipio_mensal.regiao_saude IS 'Regiao de saude a que o municipio pertence.';
COMMENT ON COLUMN vw_painel_municipio_mensal.cod_regiao_saude IS 'Codigo de 5 digitos da regiao de saude.';
COMMENT ON COLUMN vw_painel_municipio_mensal.latitude IS 'Latitude da sede do municipio, em graus decimais. Para mapas.';
COMMENT ON COLUMN vw_painel_municipio_mensal.longitude IS 'Longitude da sede do municipio, em graus decimais. Para mapas.';
COMMENT ON COLUMN vw_painel_municipio_mensal.ano IS 'Ano da competencia, com 4 digitos.';
COMMENT ON COLUMN vw_painel_municipio_mensal.mes IS 'Mes da competencia, de 1 a 12.';
COMMENT ON COLUMN vw_painel_municipio_mensal.competencia IS 'Mes de referencia no formato AAAAMM. Ordenar por ela da a ordem cronologica.';
COMMENT ON COLUMN vw_painel_municipio_mensal.hospitais IS 'Hospitais com internacao no municipio no mes.';
COMMENT ON COLUMN vw_painel_municipio_mensal.internacoes IS 'Internacoes do SUS no municipio no mes.';
COMMENT ON COLUMN vw_painel_municipio_mensal.dias_permanencia IS 'Soma dos dias de internacao no mes.';
COMMENT ON COLUMN vw_painel_municipio_mensal.leitos IS 'Leitos cadastrados no CNES no municipio.';
COMMENT ON COLUMN vw_painel_municipio_mensal.custo_total IS 'Valor pago pelo SUS no mes, em reais.';
COMMENT ON COLUMN vw_painel_municipio_mensal.permanencia_media IS 'Media de dias de internacao por paciente.';
COMMENT ON COLUMN vw_painel_municipio_mensal.ipa IS 'IPA do municipio no mes, taxa de ocupacao de leito em percentual.';
COMMENT ON COLUMN vw_painel_municipio_mensal.risco_assistencial IS 'Nivel de risco. Valores: ESTAVEL, MEDIO RISCO, CRITICO, COLAPSO.';
COMMENT ON COLUMN vw_painel_municipio_mensal.semaforo IS 'Cor do risco. Valores: VERDE, AMARELO, VERMELHO.';

-- ===========================================================================
-- VW_PAINEL_HOSPITAL
-- ===========================================================================
COMMENT ON TABLE vw_painel_hospital IS
'Desempenho mensal de cada hospital do SUS em Sao Paulo. UMA LINHA POR HOSPITAL E POR MES. Use para perguntas sobre hospitais ou estabelecimentos: permanencia media, ocupacao, custo, comparacao com a media do estado. ATENCAO: nao existe nome de hospital nesta base, apenas o codigo CNES, porque o cadastro de estabelecimentos do DATASUS nao publica a razao social no grupo de dados carregado. Identifique o hospital pelo codigo CNES e pelo nome do municipio.';

COMMENT ON COLUMN vw_painel_hospital.cod_cnes IS
'Codigo CNES do estabelecimento, o identificador nacional do hospital. Nao ha nome, use este codigo para identificar o hospital.';
COMMENT ON COLUMN vw_painel_hospital.regiao_saude IS 'Regiao de saude onde o hospital fica.';
COMMENT ON COLUMN vw_painel_hospital.cod_regiao_saude IS 'Codigo de 5 digitos da regiao de saude.';
COMMENT ON COLUMN vw_painel_hospital.cod_municipio IS 'Codigo IBGE de 6 digitos do municipio do hospital.';
COMMENT ON COLUMN vw_painel_hospital.nome_municipio IS 'Nome do municipio onde o hospital fica.';
COMMENT ON COLUMN vw_painel_hospital.sigla_uf IS 'Sigla da unidade federativa. Sempre SP, o MVP cobre so Sao Paulo.';
COMMENT ON COLUMN vw_painel_hospital.ano IS 'Ano da competencia, com 4 digitos.';
COMMENT ON COLUMN vw_painel_hospital.mes IS 'Mes da competencia, de 1 a 12.';
COMMENT ON COLUMN vw_painel_hospital.competencia IS 'Mes de referencia no formato AAAAMM.';
COMMENT ON COLUMN vw_painel_hospital.internacoes IS 'Internacoes do hospital no mes.';
COMMENT ON COLUMN vw_painel_hospital.dias_permanencia IS 'Soma dos dias de internacao do hospital no mes.';
COMMENT ON COLUMN vw_painel_hospital.permanencia_media IS
'Media de dias que o paciente fica internado neste hospital no mes. Para saber se esta acima da media do estado, compare com a coluna permanencia_media_estadual.';
COMMENT ON COLUMN vw_painel_hospital.leitos IS 'Leitos cadastrados no CNES no hospital. Fica nulo quando o hospital nao tem leito cadastrado.';
COMMENT ON COLUMN vw_painel_hospital.custo_total IS 'Valor pago pelo SUS ao hospital no mes, em reais.';
COMMENT ON COLUMN vw_painel_hospital.ipa IS
'IPA do hospital no mes, taxa de ocupacao de leito em percentual. Fica nulo quando o hospital nao tem leito cadastrado no CNES. Pode passar de 100 em hospital de longa permanencia, o que indica limitacao do dado de leito e nao ocupacao real.';
COMMENT ON COLUMN vw_painel_hospital.risco_assistencial IS 'Nivel de risco do hospital. Valores: ESTAVEL, MEDIO RISCO, CRITICO, COLAPSO.';
COMMENT ON COLUMN vw_painel_hospital.semaforo IS 'Cor do risco. Valores: VERDE, AMARELO, VERMELHO.';
COMMENT ON COLUMN vw_painel_hospital.permanencia_media_estadual IS
'Media de dias de internacao de todo o estado de Sao Paulo, em todo o periodo, ponderada pelo volume. O mesmo valor se repete em todas as linhas. Compare permanencia_media com esta coluna para responder quais hospitais estao acima da media estadual.';
COMMENT ON COLUMN vw_painel_hospital.permanencia_media_estadual_mes IS
'Media estadual de dias de internacao apenas do mes da linha, ponderada pelo volume. Use quando a comparacao tiver que respeitar o mes.';

-- ===========================================================================
-- VW_MORBIDADE_REGIAO_MENSAL
-- ===========================================================================
COMMENT ON TABLE vw_morbidade_regiao_mensal IS
'Internacoes por grupo de doenca, regiao de saude e mes, em Sao Paulo. UMA LINHA POR REGIAO, MES E CAPITULO DO CID-10. Use para qualquer pergunta que cite uma doenca ou um grupo de causas: respiratorio, cardiaco, cancer, parto, saude mental. Para pergunta sobre internacoes respiratorias filtre cid_capitulo igual a J.';

COMMENT ON COLUMN vw_morbidade_regiao_mensal.cod_regiao_saude IS 'Codigo de 5 digitos da regiao de saude.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.regiao_saude IS 'Nome da regiao de saude.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.ano IS 'Ano da competencia, com 4 digitos.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.mes IS 'Mes da competencia, de 1 a 12.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.competencia IS 'Mes de referencia no formato AAAAMM.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.cid_capitulo IS
'Letra inicial do codigo CID-10 do diagnostico principal, que identifica o capitulo da doenca. J e aparelho respiratorio, o que inclui pneumonia, asma, bronquite, gripe e DPOC. I e aparelho circulatorio, o que inclui infarto e AVC. C e cancer. O e gravidez e parto. F e saude mental. K e aparelho digestivo. N e rins e vias urinarias. S e T sao acidentes e violencia. A e B sao doencas infecciosas, o que inclui dengue.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.grupo_doenca IS
'Nome do capitulo do CID-10 em portugues. Prefira esta coluna a letra do capitulo quando for mostrar o resultado ao usuario.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.internacoes IS 'Internacoes daquele grupo de doenca na regiao no mes.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.dias_permanencia IS 'Soma dos dias de internacao.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.permanencia_media IS 'Media de dias de internacao.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.obitos_hospitalares IS
'Obitos ocorridos durante a internacao. NAO e o total de mortes da populacao, so as que aconteceram internado. O total esta em VW_VITAL_REGIAO_ANUAL.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.taxa_mortalidade_pct IS
'Percentual de internacoes que terminaram em obito. A media do estado fica proxima de 4,8 por cento.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.internacoes_com_uti IS 'Internacoes que usaram UTI.';
COMMENT ON COLUMN vw_morbidade_regiao_mensal.custo_total IS 'Valor pago pelo SUS, em reais.';

-- ===========================================================================
-- VW_FLUXO_REGIAO
-- ===========================================================================
COMMENT ON TABLE vw_fluxo_regiao IS
'Fluxo de pacientes entre regioes de saude de Sao Paulo. UMA LINHA PARA CADA PAR de regiao onde o paciente MORA e regiao onde ele se INTERNOU. Use para perguntas sobre pacientes que saem da propria regiao, evasao, dependencia de outra regiao, regiao que atrai ou que exporta paciente, e falta de leito local. Uma regiao que manda muito paciente para fora e uma regiao que nao consegue atender a propria populacao. Cobre o periodo inteiro carregado, nao e mensal.';

COMMENT ON COLUMN vw_fluxo_regiao.regiao_residencia IS 'Regiao de saude onde o paciente mora.';
COMMENT ON COLUMN vw_fluxo_regiao.regiao_internacao IS 'Regiao de saude onde o paciente foi internado.';
COMMENT ON COLUMN vw_fluxo_regiao.saiu_da_regiao IS
'Indica se o paciente se internou fora da propria regiao. Valores: S para sim, N para nao. Filtre por S para achar evasao de pacientes.';
COMMENT ON COLUMN vw_fluxo_regiao.internacoes IS 'Internacoes naquele par de regioes.';
COMMENT ON COLUMN vw_fluxo_regiao.dias_permanencia IS 'Soma dos dias de internacao.';
COMMENT ON COLUMN vw_fluxo_regiao.obitos_hospitalares IS 'Obitos durante a internacao.';
COMMENT ON COLUMN vw_fluxo_regiao.custo_total IS 'Valor pago pelo SUS, em reais.';

-- ===========================================================================
-- VW_VITAL_REGIAO_ANUAL
-- ===========================================================================
COMMENT ON TABLE vw_vital_regiao_anual IS
'Obitos e nascidos vivos por regiao de saude e ano, em Sao Paulo, pelo municipio de residencia da pessoa. UMA LINHA POR REGIAO E ANO. Fonte SIM para obitos e SINASC para nascimentos. ATENCAO IMPORTANTE: a janela de tempo NAO e a mesma das internacoes. Obitos cobrem de 2021 a 2024 e nascimentos de 2020 a 2022, porque essas bases do Ministerio da Saude atrasam de um a dois anos. As internacoes cobrem de junho de 2024 a maio de 2026. NAO cruze esta view com as de internacao pelo mesmo ano, os periodos nao se encontram. Se a pergunta pedir esse cruzamento, responda que os periodos sao diferentes.';

COMMENT ON COLUMN vw_vital_regiao_anual.cod_regiao_saude IS 'Codigo de 5 digitos da regiao de saude.';
COMMENT ON COLUMN vw_vital_regiao_anual.regiao_saude IS 'Nome da regiao de saude.';
COMMENT ON COLUMN vw_vital_regiao_anual.ano IS 'Ano do obito ou do nascimento, com 4 digitos.';
COMMENT ON COLUMN vw_vital_regiao_anual.obitos IS
'Total de obitos de residentes da regiao no ano, de qualquer causa, dentro ou fora do hospital. Fonte SIM. So tem dado de 2021 a 2024.';
COMMENT ON COLUMN vw_vital_regiao_anual.obitos_respiratorios IS 'Obitos por doenca do aparelho respiratorio, capitulo J do CID-10.';
COMMENT ON COLUMN vw_vital_regiao_anual.obitos_circulatorios IS 'Obitos por doenca do aparelho circulatorio, capitulo I do CID-10, que inclui infarto e AVC.';
COMMENT ON COLUMN vw_vital_regiao_anual.obitos_menores_1_ano IS 'Obitos de criancas com menos de 1 ano. Numerador da mortalidade infantil.';
COMMENT ON COLUMN vw_vital_regiao_anual.nascidos_vivos IS
'Nascidos vivos de maes residentes na regiao no ano. Fonte SINASC. So tem dado de 2020 a 2022. E o denominador da mortalidade infantil.';
COMMENT ON COLUMN vw_vital_regiao_anual.nascidos_baixo_peso IS 'Nascidos com menos de 2500 gramas.';
COMMENT ON COLUMN vw_vital_regiao_anual.nascidos_prematuros IS 'Nascidos antes de 37 semanas de gestacao.';
COMMENT ON COLUMN vw_vital_regiao_anual.nascidos_sem_prenatal IS 'Nascidos de maes que nao fizeram nenhuma consulta de pre-natal. Indicador de falha da atencao basica.';
COMMENT ON COLUMN vw_vital_regiao_anual.filhos_de_mae_adolescente IS 'Nascidos de maes com menos de 20 anos.';

-- ===========================================================================
-- GLD_FAIXA_RISCO
-- ===========================================================================
COMMENT ON TABLE gld_faixa_risco IS
'Tabela de referencia com os pontos de corte que transformam o IPA em nivel de risco e em cor de semaforo. Consulte quando a pergunta for sobre o que significa cada faixa ou a partir de que valor uma regiao entra em alerta.';
COMMENT ON COLUMN gld_faixa_risco.nivel IS 'Nome do nivel. Valores: ESTAVEL, MEDIO RISCO, CRITICO, COLAPSO.';
COMMENT ON COLUMN gld_faixa_risco.ordem IS 'Ordem de gravidade, de 1 para o mais tranquilo a 4 para o mais grave.';
COMMENT ON COLUMN gld_faixa_risco.ipa_min IS 'Menor IPA da faixa, em percentual.';
COMMENT ON COLUMN gld_faixa_risco.ipa_max IS 'Maior IPA da faixa, em percentual.';
COMMENT ON COLUMN gld_faixa_risco.cor IS 'Cor em hexadecimal usada no painel.';
COMMENT ON COLUMN gld_faixa_risco.semaforo IS 'Cor do semaforo de tres niveis. Valores: VERDE, AMARELO, VERMELHO.';
