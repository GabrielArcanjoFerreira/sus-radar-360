# Dicionario de dados

> Gerado por `scripts/gen_dicionario.py` a partir do Autonomous Database.
> Nao editar a mao — as descricoes de negocio ficam no proprio script.

## BRONZE

5 tabelas. 9.045.693 linhas.

### `BRZ_CNES_LT`

CNES LT cru — leitos por estabelecimento e tipo

**8.327 linhas · 28 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CNES` | VARCHAR2(40) | sim |  |
| `CODUFMUN` | VARCHAR2(40) | sim | municipio do estabelecimento (IBGE) |
| `REGSAUDE` | VARCHAR2(40) | sim | NAO CONFIAVEL: texto livre, 56% em branco, 291 valores distintos |
| `MICR_REG` | VARCHAR2(40) | sim |  |
| `DISTRSAN` | VARCHAR2(40) | sim |  |
| `DISTRADM` | VARCHAR2(40) | sim |  |
| `TPGESTAO` | VARCHAR2(40) | sim |  |
| `PF_PJ` | VARCHAR2(40) | sim |  |
| `CPF_CNPJ` | VARCHAR2(68) | sim |  |
| `NIV_DEP` | VARCHAR2(40) | sim |  |
| `CNPJ_MAN` | VARCHAR2(68) | sim |  |
| `ESFERA_A` | VARCHAR2(40) | sim |  |
| `ATIVIDAD` | VARCHAR2(40) | sim |  |
| `RETENCAO` | VARCHAR2(40) | sim |  |
| `NATUREZA` | VARCHAR2(40) | sim |  |
| `CLIENTEL` | VARCHAR2(40) | sim |  |
| `TP_UNID` | VARCHAR2(40) | sim | tipo de unidade |
| `TURNO_AT` | VARCHAR2(40) | sim |  |
| `NIV_HIER` | VARCHAR2(40) | sim |  |
| `TERCEIRO` | VARCHAR2(40) | sim |  |
| `TP_LEITO` | VARCHAR2(40) | sim | tipo de leito |
| `CODLEITO` | VARCHAR2(40) | sim |  |
| `QT_EXIST` | NUMBER(19) | sim | leitos existentes |
| `QT_CONTR` | NUMBER(19) | sim | leitos contratados |
| `QT_SUS` | NUMBER(19) | sim | leitos SUS |
| `QT_NSUS` | NUMBER(19) | sim |  |
| `COMPETEN` | VARCHAR2(40) | sim |  |
| `NAT_JUR` | VARCHAR2(40) | sim | natureza juridica |

### `BRZ_CNES_ST`

CNES ST cru — cadastro de estabelecimentos

**115.148 linhas · 208 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CNES` | VARCHAR2(40) | sim |  |
| `CODUFMUN` | VARCHAR2(40) | sim | municipio do estabelecimento (IBGE) |
| `COD_CEP` | VARCHAR2(40) | sim |  |
| `CPF_CNPJ` | VARCHAR2(68) | sim |  |
| `PF_PJ` | VARCHAR2(40) | sim |  |
| `NIV_DEP` | VARCHAR2(40) | sim |  |
| `CNPJ_MAN` | VARCHAR2(68) | sim |  |
| `COD_IR` | VARCHAR2(40) | sim |  |
| `REGSAUDE` | VARCHAR2(40) | sim | NAO CONFIAVEL: texto livre, 56% em branco, 291 valores distintos |
| `MICR_REG` | VARCHAR2(40) | sim |  |
| `DISTRSAN` | VARCHAR2(40) | sim |  |
| `DISTRADM` | VARCHAR2(40) | sim |  |
| `VINC_SUS` | VARCHAR2(40) | sim | atende SUS |
| `TPGESTAO` | VARCHAR2(40) | sim |  |
| `ESFERA_A` | VARCHAR2(40) | sim |  |
| `RETENCAO` | VARCHAR2(40) | sim |  |
| `ATIVIDAD` | VARCHAR2(40) | sim |  |
| `NATUREZA` | VARCHAR2(40) | sim |  |
| `CLIENTEL` | VARCHAR2(40) | sim |  |
| `TP_UNID` | VARCHAR2(40) | sim | tipo de unidade |
| `TURNO_AT` | VARCHAR2(40) | sim |  |
| `NIV_HIER` | VARCHAR2(40) | sim |  |
| `TP_PREST` | VARCHAR2(40) | sim |  |
| `CO_BANCO` | VARCHAR2(40) | sim |  |
| `CO_AGENC` | VARCHAR2(40) | sim |  |
| `C_CORREN` | VARCHAR2(68) | sim |  |
| `CONTRATM` | VARCHAR2(40) | sim |  |
| `DT_PUBLM` | VARCHAR2(40) | sim |  |
| `CONTRATE` | VARCHAR2(40) | sim |  |
| `DT_PUBLE` | VARCHAR2(40) | sim |  |
| `ALVARA` | VARCHAR2(124) | sim |  |
| `DT_EXPED` | VARCHAR2(40) | sim |  |
| `ORGEXPED` | VARCHAR2(40) | sim |  |
| `AV_ACRED` | VARCHAR2(40) | sim |  |
| `CLASAVAL` | VARCHAR2(40) | sim |  |
| `DT_ACRED` | VARCHAR2(40) | sim |  |
| `AV_PNASS` | VARCHAR2(40) | sim |  |
| `DT_PNASS` | VARCHAR2(40) | sim |  |
| `GESPRG1E` | VARCHAR2(40) | sim |  |
| `GESPRG1M` | VARCHAR2(40) | sim |  |
| `GESPRG2E` | VARCHAR2(40) | sim |  |
| `GESPRG2M` | VARCHAR2(40) | sim |  |
| `GESPRG4E` | VARCHAR2(40) | sim |  |
| `GESPRG4M` | VARCHAR2(40) | sim |  |
| `NIVATE_A` | VARCHAR2(40) | sim |  |
| `GESPRG3E` | VARCHAR2(40) | sim |  |
| `GESPRG3M` | VARCHAR2(40) | sim |  |
| `GESPRG5E` | VARCHAR2(40) | sim |  |
| `GESPRG5M` | VARCHAR2(40) | sim |  |
| `GESPRG6E` | VARCHAR2(40) | sim |  |
| `GESPRG6M` | VARCHAR2(40) | sim |  |
| `NIVATE_H` | VARCHAR2(40) | sim |  |
| `QTLEITP1` | NUMBER(19) | sim |  |
| `QTLEITP2` | NUMBER(19) | sim |  |
| `QTLEITP3` | NUMBER(19) | sim |  |
| `LEITHOSP` | VARCHAR2(40) | sim |  |
| `QTINST01` | NUMBER(19) | sim |  |
| `QTINST02` | NUMBER(19) | sim |  |
| `QTINST03` | NUMBER(19) | sim |  |
| `QTINST04` | NUMBER(19) | sim |  |
| `QTINST05` | NUMBER(19) | sim |  |
| `QTINST06` | NUMBER(19) | sim |  |
| `QTINST07` | NUMBER(19) | sim |  |
| `QTINST08` | NUMBER(19) | sim |  |
| `QTINST09` | NUMBER(19) | sim |  |
| `QTINST10` | NUMBER(19) | sim |  |
| `QTINST11` | NUMBER(19) | sim |  |
| `QTINST12` | NUMBER(19) | sim |  |
| `QTINST13` | NUMBER(19) | sim |  |
| `QTINST14` | NUMBER(19) | sim |  |
| `URGEMERG` | VARCHAR2(40) | sim |  |
| `QTINST15` | NUMBER(19) | sim |  |
| `QTINST16` | NUMBER(19) | sim |  |
| `QTINST17` | NUMBER(19) | sim |  |
| `QTINST18` | NUMBER(19) | sim |  |
| `QTINST19` | NUMBER(19) | sim |  |
| `QTINST20` | NUMBER(19) | sim |  |
| `QTINST21` | NUMBER(19) | sim |  |
| `QTINST22` | NUMBER(19) | sim |  |
| `QTINST23` | NUMBER(19) | sim |  |
| `QTINST24` | NUMBER(19) | sim |  |
| `QTINST25` | NUMBER(19) | sim |  |
| `QTINST26` | NUMBER(19) | sim |  |
| `QTINST27` | NUMBER(19) | sim |  |
| `QTINST28` | NUMBER(19) | sim |  |
| `QTINST29` | NUMBER(19) | sim |  |
| `QTINST30` | NUMBER(19) | sim |  |
| `ATENDAMB` | VARCHAR2(40) | sim |  |
| `QTINST31` | NUMBER(19) | sim |  |
| `QTINST32` | NUMBER(19) | sim |  |
| `QTINST33` | NUMBER(19) | sim |  |
| `CENTRCIR` | VARCHAR2(40) | sim |  |
| `QTINST34` | NUMBER(19) | sim |  |
| `QTINST35` | NUMBER(19) | sim |  |
| `QTINST36` | NUMBER(19) | sim |  |
| `QTINST37` | NUMBER(19) | sim |  |
| `CENTROBS` | VARCHAR2(40) | sim |  |
| `QTLEIT05` | NUMBER(19) | sim |  |
| `QTLEIT06` | NUMBER(19) | sim |  |
| `QTLEIT07` | NUMBER(19) | sim |  |
| `QTLEIT08` | NUMBER(19) | sim |  |
| `QTLEIT09` | NUMBER(19) | sim |  |
| `QTLEIT19` | NUMBER(19) | sim |  |
| `QTLEIT20` | NUMBER(19) | sim |  |
| `QTLEIT21` | NUMBER(19) | sim |  |
| `QTLEIT22` | NUMBER(19) | sim |  |
| `QTLEIT23` | NUMBER(19) | sim |  |
| `QTLEIT32` | NUMBER(19) | sim |  |
| `QTLEIT34` | NUMBER(19) | sim |  |
| `QTLEIT38` | NUMBER(19) | sim |  |
| `QTLEIT39` | NUMBER(19) | sim |  |
| `QTLEIT40` | NUMBER(19) | sim |  |
| `CENTRNEO` | VARCHAR2(40) | sim |  |
| `ATENDHOS` | VARCHAR2(40) | sim |  |
| `SERAP01P` | VARCHAR2(40) | sim |  |
| `SERAP01T` | VARCHAR2(40) | sim |  |
| `SERAP02P` | VARCHAR2(40) | sim |  |
| `SERAP02T` | VARCHAR2(40) | sim |  |
| `SERAP03P` | VARCHAR2(40) | sim |  |
| `SERAP03T` | VARCHAR2(40) | sim |  |
| `SERAP04P` | VARCHAR2(40) | sim |  |
| `SERAP04T` | VARCHAR2(40) | sim |  |
| `SERAP05P` | VARCHAR2(40) | sim |  |
| `SERAP05T` | VARCHAR2(40) | sim |  |
| `SERAP06P` | VARCHAR2(40) | sim |  |
| `SERAP06T` | VARCHAR2(40) | sim |  |
| `SERAP07P` | VARCHAR2(40) | sim |  |
| `SERAP07T` | VARCHAR2(40) | sim |  |
| `SERAP08P` | VARCHAR2(40) | sim |  |
| `SERAP08T` | VARCHAR2(40) | sim |  |
| `SERAP09P` | VARCHAR2(40) | sim |  |
| `SERAP09T` | VARCHAR2(40) | sim |  |
| `SERAP10P` | VARCHAR2(40) | sim |  |
| `SERAP10T` | VARCHAR2(40) | sim |  |
| `SERAP11P` | VARCHAR2(40) | sim |  |
| `SERAP11T` | VARCHAR2(40) | sim |  |
| `SERAPOIO` | VARCHAR2(40) | sim |  |
| `RES_BIOL` | VARCHAR2(40) | sim |  |
| `RES_QUIM` | VARCHAR2(40) | sim |  |
| `RES_RADI` | VARCHAR2(40) | sim |  |
| `RES_COMU` | VARCHAR2(40) | sim |  |
| `COLETRES` | VARCHAR2(40) | sim |  |
| `COMISS01` | VARCHAR2(40) | sim |  |
| `COMISS02` | VARCHAR2(40) | sim |  |
| `COMISS03` | VARCHAR2(40) | sim |  |
| `COMISS04` | VARCHAR2(40) | sim |  |
| `COMISS05` | VARCHAR2(40) | sim |  |
| `COMISS06` | VARCHAR2(40) | sim |  |
| `COMISS07` | VARCHAR2(40) | sim |  |
| `COMISS08` | VARCHAR2(40) | sim |  |
| `COMISS09` | VARCHAR2(40) | sim |  |
| `COMISS10` | VARCHAR2(40) | sim |  |
| `COMISS11` | VARCHAR2(40) | sim |  |
| `COMISS12` | VARCHAR2(40) | sim |  |
| `COMISSAO` | VARCHAR2(40) | sim |  |
| `AP01CV01` | VARCHAR2(40) | sim |  |
| `AP01CV02` | VARCHAR2(40) | sim |  |
| `AP01CV03` | VARCHAR2(40) | sim |  |
| `AP01CV04` | VARCHAR2(40) | sim |  |
| `AP01CV05` | VARCHAR2(40) | sim |  |
| `AP01CV06` | VARCHAR2(40) | sim |  |
| `AP01CV07` | VARCHAR2(40) | sim |  |
| `AP02CV01` | VARCHAR2(40) | sim |  |
| `AP02CV02` | VARCHAR2(40) | sim |  |
| `AP02CV03` | VARCHAR2(40) | sim |  |
| `AP02CV04` | VARCHAR2(40) | sim |  |
| `AP02CV05` | VARCHAR2(40) | sim |  |
| `AP02CV06` | VARCHAR2(40) | sim |  |
| `AP02CV07` | VARCHAR2(40) | sim |  |
| `AP03CV01` | VARCHAR2(40) | sim |  |
| `AP03CV02` | VARCHAR2(40) | sim |  |
| `AP03CV03` | VARCHAR2(40) | sim |  |
| `AP03CV04` | VARCHAR2(40) | sim |  |
| `AP03CV05` | VARCHAR2(40) | sim |  |
| `AP03CV06` | VARCHAR2(40) | sim |  |
| `AP03CV07` | VARCHAR2(40) | sim |  |
| `AP04CV01` | VARCHAR2(40) | sim |  |
| `AP04CV02` | VARCHAR2(40) | sim |  |
| `AP04CV03` | VARCHAR2(40) | sim |  |
| `AP04CV04` | VARCHAR2(40) | sim |  |
| `AP04CV05` | VARCHAR2(40) | sim |  |
| `AP04CV06` | VARCHAR2(40) | sim |  |
| `AP04CV07` | VARCHAR2(40) | sim |  |
| `AP05CV01` | VARCHAR2(40) | sim |  |
| `AP05CV02` | VARCHAR2(40) | sim |  |
| `AP05CV03` | VARCHAR2(40) | sim |  |
| `AP05CV04` | VARCHAR2(40) | sim |  |
| `AP05CV05` | VARCHAR2(40) | sim |  |
| `AP05CV06` | VARCHAR2(40) | sim |  |
| `AP05CV07` | VARCHAR2(40) | sim |  |
| `AP06CV01` | VARCHAR2(40) | sim |  |
| `AP06CV02` | VARCHAR2(40) | sim |  |
| `AP06CV03` | VARCHAR2(40) | sim |  |
| `AP06CV04` | VARCHAR2(40) | sim |  |
| `AP06CV05` | VARCHAR2(40) | sim |  |
| `AP06CV06` | VARCHAR2(40) | sim |  |
| `AP06CV07` | VARCHAR2(40) | sim |  |
| `AP07CV01` | VARCHAR2(40) | sim |  |
| `AP07CV02` | VARCHAR2(40) | sim |  |
| `AP07CV03` | VARCHAR2(40) | sim |  |
| `AP07CV04` | VARCHAR2(40) | sim |  |
| `AP07CV05` | VARCHAR2(40) | sim |  |
| `AP07CV06` | VARCHAR2(40) | sim |  |
| `AP07CV07` | VARCHAR2(40) | sim |  |
| `ATEND_PR` | VARCHAR2(40) | sim |  |
| `DT_ATUAL` | VARCHAR2(40) | sim |  |
| `COMPETEN` | VARCHAR2(40) | sim |  |
| `NAT_JUR` | VARCHAR2(40) | sim | natureza juridica |

### `BRZ_SIH_RD`

SIHSUS RD cru — 1 linha = 1 AIH (internacao paga pelo SUS)

**5.860.558 linhas · 114 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `UF_ZI` | VARCHAR2(40) | sim |  |
| `ANO_CMPT` | VARCHAR2(40) | sim | ano da competencia de faturamento |
| `MES_CMPT` | VARCHAR2(40) | sim | mes da competencia |
| `ESPEC` | VARCHAR2(40) | sim | especialidade do leito |
| `CGC_HOSP` | VARCHAR2(68) | sim |  |
| `N_AIH` | VARCHAR2(64) | sim | numero da AIH |
| `IDENT` | VARCHAR2(40) | sim |  |
| `CEP` | VARCHAR2(40) | sim |  |
| `MUNIC_RES` | VARCHAR2(40) | sim | municipio de RESIDENCIA (IBGE) |
| `NASC` | VARCHAR2(40) | sim |  |
| `SEXO` | VARCHAR2(40) | sim | no SIH: 1=M, 3=F (difere do SIM) |
| `UTI_MES_IN` | NUMBER(19) | sim |  |
| `UTI_MES_AN` | NUMBER(19) | sim |  |
| `UTI_MES_AL` | NUMBER(19) | sim |  |
| `UTI_MES_TO` | NUMBER(19) | sim | diarias de UTI no mes |
| `MARCA_UTI` | VARCHAR2(40) | sim |  |
| `UTI_INT_IN` | NUMBER(19) | sim |  |
| `UTI_INT_AN` | NUMBER(19) | sim |  |
| `UTI_INT_AL` | NUMBER(19) | sim |  |
| `UTI_INT_TO` | NUMBER(19) | sim |  |
| `DIAR_ACOM` | NUMBER(19) | sim |  |
| `QT_DIARIAS` | NUMBER(19) | sim |  |
| `PROC_SOLIC` | VARCHAR2(52) | sim |  |
| `PROC_REA` | VARCHAR2(52) | sim | procedimento SIGTAP realizado |
| `VAL_SH` | NUMBER | sim |  |
| `VAL_SP` | NUMBER | sim |  |
| `VAL_SADT` | NUMBER | sim |  |
| `VAL_RN` | NUMBER | sim |  |
| `VAL_ACOMP` | NUMBER | sim |  |
| `VAL_ORTP` | NUMBER | sim |  |
| `VAL_SANGUE` | NUMBER | sim |  |
| `VAL_SADTSR` | NUMBER | sim |  |
| `VAL_TRANSP` | NUMBER | sim |  |
| `VAL_OBSANG` | NUMBER | sim |  |
| `VAL_PED1AC` | NUMBER | sim |  |
| `VAL_TOT` | NUMBER | sim | valor total faturado |
| `VAL_UTI` | NUMBER | sim |  |
| `US_TOT` | NUMBER | sim |  |
| `DT_INTER` | VARCHAR2(40) | sim | data de admissao (AAAAMMDD) |
| `DT_SAIDA` | VARCHAR2(40) | sim |  |
| `DIAG_PRINC` | VARCHAR2(40) | sim | CID-10 principal |
| `DIAG_SECUN` | VARCHAR2(40) | sim |  |
| `COBRANCA` | VARCHAR2(40) | sim |  |
| `NATUREZA` | VARCHAR2(40) | sim |  |
| `NAT_JUR` | VARCHAR2(40) | sim | natureza juridica |
| `GESTAO` | VARCHAR2(40) | sim |  |
| `RUBRICA` | NUMBER(19) | sim |  |
| `IND_VDRL` | VARCHAR2(40) | sim |  |
| `MUNIC_MOV` | VARCHAR2(40) | sim | municipio de INTERNACAO (IBGE) |
| `COD_IDADE` | VARCHAR2(40) | sim | unidade de IDADE: 2=dias 3=meses 4=anos 5=100+anos |
| `IDADE` | NUMBER(19) | sim | no SIM vem codificada: 1o digito = unidade |
| `DIAS_PERM` | NUMBER(19) | sim | dias de permanencia |
| `MORTE` | NUMBER(19) | sim |  |
| `NACIONAL` | VARCHAR2(40) | sim |  |
| `NUM_PROC` | VARCHAR2(40) | sim |  |
| `CAR_INT` | VARCHAR2(40) | sim | carater da internacao |
| `TOT_PT_SP` | NUMBER(19) | sim |  |
| `CPF_AUT` | VARCHAR2(40) | sim |  |
| `HOMONIMO` | VARCHAR2(40) | sim |  |
| `NUM_FILHOS` | NUMBER(19) | sim |  |
| `INSTRU` | VARCHAR2(40) | sim |  |
| `CID_NOTIF` | VARCHAR2(40) | sim |  |
| `CONTRACEP1` | VARCHAR2(40) | sim |  |
| `CONTRACEP2` | VARCHAR2(40) | sim |  |
| `GESTRISCO` | VARCHAR2(40) | sim |  |
| `INSC_PN` | VARCHAR2(60) | sim |  |
| `SEQ_AIH5` | VARCHAR2(40) | sim |  |
| `CBOR` | VARCHAR2(40) | sim |  |
| `CNAER` | VARCHAR2(40) | sim |  |
| `VINCPREV` | VARCHAR2(40) | sim |  |
| `GESTOR_COD` | VARCHAR2(40) | sim |  |
| `GESTOR_TP` | VARCHAR2(40) | sim |  |
| `GESTOR_CPF` | VARCHAR2(76) | sim |  |
| `GESTOR_DT` | VARCHAR2(40) | sim |  |
| `CNES` | VARCHAR2(40) | sim |  |
| `CNPJ_MANT` | VARCHAR2(68) | sim |  |
| `INFEHOSP` | VARCHAR2(40) | sim |  |
| `CID_ASSO` | VARCHAR2(40) | sim |  |
| `CID_MORTE` | VARCHAR2(40) | sim |  |
| `COMPLEX` | VARCHAR2(40) | sim | complexidade |
| `FINANC` | VARCHAR2(40) | sim |  |
| `FAEC_TP` | VARCHAR2(40) | sim |  |
| `REGCT` | VARCHAR2(40) | sim |  |
| `RACA_COR` | VARCHAR2(40) | sim |  |
| `ETNIA` | VARCHAR2(40) | sim |  |
| `SEQUENCIA` | NUMBER(19) | sim |  |
| `REMESSA` | VARCHAR2(104) | sim |  |
| `AUD_JUST` | VARCHAR2(244) | sim |  |
| `SIS_JUST` | VARCHAR2(244) | sim |  |
| `VAL_SH_FED` | NUMBER | sim |  |
| `VAL_SP_FED` | NUMBER | sim |  |
| `VAL_SH_GES` | NUMBER | sim |  |
| `VAL_SP_GES` | NUMBER | sim |  |
| `VAL_UCI` | NUMBER | sim |  |
| `MARCA_UCI` | VARCHAR2(40) | sim |  |
| `DIAGSEC1` | VARCHAR2(40) | sim |  |
| `DIAGSEC2` | VARCHAR2(40) | sim |  |
| `DIAGSEC3` | VARCHAR2(40) | sim |  |
| `DIAGSEC4` | VARCHAR2(40) | sim |  |
| `DIAGSEC5` | VARCHAR2(40) | sim |  |
| `DIAGSEC6` | VARCHAR2(40) | sim |  |
| `DIAGSEC7` | VARCHAR2(40) | sim |  |
| `DIAGSEC8` | VARCHAR2(40) | sim |  |
| `DIAGSEC9` | VARCHAR2(40) | sim |  |
| `TPDISEC1` | VARCHAR2(40) | sim |  |
| `TPDISEC2` | VARCHAR2(40) | sim |  |
| `TPDISEC3` | VARCHAR2(40) | sim |  |
| `TPDISEC4` | VARCHAR2(40) | sim |  |
| `TPDISEC5` | VARCHAR2(40) | sim |  |
| `TPDISEC6` | VARCHAR2(40) | sim |  |
| `TPDISEC7` | VARCHAR2(40) | sim |  |
| `TPDISEC8` | VARCHAR2(40) | sim |  |
| `TPDISEC9` | VARCHAR2(40) | sim |  |
| `FONTE_ORC` | VARCHAR2(40) | sim | fonte do recurso; so existe de 2025-03 em diante |

### `BRZ_SIM_DO`

SIM DO cru — declaracoes de obito

**1.471.591 linhas · 87 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `ORIGEM` | VARCHAR2(40) | sim |  |
| `TIPOBITO` | VARCHAR2(40) | sim |  |
| `DTOBITO` | VARCHAR2(40) | sim | data do obito (DDMMAAAA) |
| `HORAOBITO` | VARCHAR2(40) | sim |  |
| `NATURAL` | VARCHAR2(40) | sim |  |
| `CODMUNNATU` | VARCHAR2(40) | sim |  |
| `DTNASC` | VARCHAR2(40) | sim | data de nascimento (DDMMAAAA) |
| `IDADE` | VARCHAR2(40) | sim | no SIM vem codificada: 1o digito = unidade |
| `SEXO` | VARCHAR2(40) | sim | no SIH: 1=M, 3=F (difere do SIM) |
| `RACACOR` | VARCHAR2(40) | sim |  |
| `ESTCIV` | VARCHAR2(40) | sim |  |
| `ESC` | VARCHAR2(40) | sim |  |
| `ESC2010` | VARCHAR2(40) | sim |  |
| `SERIESCFAL` | VARCHAR2(40) | sim |  |
| `OCUP` | VARCHAR2(40) | sim |  |
| `CODMUNRES` | VARCHAR2(40) | sim | municipio de residencia (IBGE) |
| `LOCOCOR` | VARCHAR2(40) | sim | local de ocorrencia |
| `CODESTAB` | VARCHAR2(40) | sim |  |
| `ESTABDESCR` | VARCHAR2(40) | sim |  |
| `CODMUNOCOR` | VARCHAR2(40) | sim |  |
| `IDADEMAE` | VARCHAR2(40) | sim | idade da mae |
| `ESCMAE` | VARCHAR2(40) | sim |  |
| `ESCMAE2010` | VARCHAR2(40) | sim |  |
| `SERIESCMAE` | VARCHAR2(40) | sim |  |
| `OCUPMAE` | VARCHAR2(40) | sim |  |
| `QTDFILVIVO` | VARCHAR2(40) | sim |  |
| `QTDFILMORT` | VARCHAR2(40) | sim |  |
| `GRAVIDEZ` | VARCHAR2(40) | sim |  |
| `SEMAGESTAC` | VARCHAR2(40) | sim |  |
| `GESTACAO` | VARCHAR2(40) | sim | faixa de semanas de gestacao |
| `PARTO` | VARCHAR2(40) | sim |  |
| `OBITOPARTO` | VARCHAR2(40) | sim |  |
| `PESO` | VARCHAR2(40) | sim | peso ao nascer em gramas |
| `TPMORTEOCO` | VARCHAR2(40) | sim |  |
| `OBITOGRAV` | VARCHAR2(40) | sim |  |
| `OBITOPUERP` | VARCHAR2(40) | sim |  |
| `ASSISTMED` | VARCHAR2(40) | sim |  |
| `EXAME` | VARCHAR2(40) | sim |  |
| `CIRURGIA` | VARCHAR2(40) | sim |  |
| `NECROPSIA` | VARCHAR2(40) | sim |  |
| `LINHAA` | VARCHAR2(100) | sim |  |
| `LINHAB` | VARCHAR2(100) | sim |  |
| `LINHAC` | VARCHAR2(100) | sim |  |
| `LINHAD` | VARCHAR2(100) | sim |  |
| `LINHAII` | VARCHAR2(148) | sim |  |
| `CAUSABAS` | VARCHAR2(40) | sim | CID-10 da causa basica |
| `CB_PRE` | VARCHAR2(40) | sim |  |
| `COMUNSVOIM` | VARCHAR2(40) | sim |  |
| `DTATESTADO` | VARCHAR2(40) | sim |  |
| `CIRCOBITO` | VARCHAR2(40) | sim |  |
| `ACIDTRAB` | VARCHAR2(40) | sim |  |
| `FONTE` | VARCHAR2(40) | sim |  |
| `NUMEROLOTE` | VARCHAR2(40) | sim |  |
| `TPPOS` | VARCHAR2(40) | sim |  |
| `DTINVESTIG` | VARCHAR2(40) | sim |  |
| `CAUSABAS_O` | VARCHAR2(40) | sim |  |
| `DTCADASTRO` | VARCHAR2(40) | sim |  |
| `ATESTANTE` | VARCHAR2(40) | sim |  |
| `STCODIFICA` | VARCHAR2(40) | sim |  |
| `CODIFICADO` | VARCHAR2(40) | sim |  |
| `VERSAOSIST` | VARCHAR2(40) | sim |  |
| `VERSAOSCB` | VARCHAR2(40) | sim |  |
| `FONTEINV` | VARCHAR2(40) | sim |  |
| `DTRECEBIM` | VARCHAR2(40) | sim |  |
| `ATESTADO` | VARCHAR2(244) | sim |  |
| `DTRECORIGA` | VARCHAR2(40) | sim |  |
| `CAUSAMAT` | VARCHAR2(40) | sim |  |
| `ESCMAEAGR1` | VARCHAR2(40) | sim |  |
| `ESCFALAGR1` | VARCHAR2(40) | sim |  |
| `STDOEPIDEM` | VARCHAR2(40) | sim |  |
| `STDONOVA` | VARCHAR2(40) | sim |  |
| `DIFDATA` | VARCHAR2(40) | sim |  |
| `NUDIASOBCO` | VARCHAR2(40) | sim |  |
| `NUDIASOBIN` | VARCHAR2(40) | sim |  |
| `DTCADINV` | VARCHAR2(40) | sim |  |
| `TPOBITOCOR` | VARCHAR2(40) | sim |  |
| `DTCONINV` | VARCHAR2(40) | sim |  |
| `FONTES` | VARCHAR2(40) | sim |  |
| `TPRESGINFO` | VARCHAR2(40) | sim |  |
| `TPNIVELINV` | VARCHAR2(40) | sim |  |
| `NUDIASINF` | VARCHAR2(40) | sim |  |
| `DTCADINF` | VARCHAR2(40) | sim |  |
| `MORTEPARTO` | VARCHAR2(40) | sim |  |
| `DTCONCASO` | VARCHAR2(40) | sim |  |
| `FONTESINF` | VARCHAR2(40) | sim |  |
| `ALTCAUSA` | VARCHAR2(40) | sim |  |
| `CONTADOR` | VARCHAR2(40) | sim |  |

### `BRZ_SINASC_DN`

SINASC DN cru — declaracoes de nascido vivo

**1.590.069 linhas · 61 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `ORIGEM` | VARCHAR2(40) | sim |  |
| `CODESTAB` | VARCHAR2(40) | sim |  |
| `CODMUNNASC` | VARCHAR2(40) | sim |  |
| `LOCNASC` | VARCHAR2(40) | sim |  |
| `IDADEMAE` | VARCHAR2(40) | sim | idade da mae |
| `ESTCIVMAE` | VARCHAR2(40) | sim |  |
| `ESCMAE` | VARCHAR2(40) | sim |  |
| `CODOCUPMAE` | VARCHAR2(40) | sim |  |
| `QTDFILVIVO` | VARCHAR2(40) | sim |  |
| `QTDFILMORT` | VARCHAR2(40) | sim |  |
| `CODMUNRES` | VARCHAR2(40) | sim | municipio de residencia (IBGE) |
| `GESTACAO` | VARCHAR2(40) | sim | faixa de semanas de gestacao |
| `GRAVIDEZ` | VARCHAR2(40) | sim |  |
| `PARTO` | VARCHAR2(40) | sim |  |
| `CONSULTAS` | VARCHAR2(40) | sim | faixa de consultas de pre-natal |
| `DTNASC` | VARCHAR2(40) | sim | data de nascimento (DDMMAAAA) |
| `HORANASC` | VARCHAR2(40) | sim |  |
| `SEXO` | VARCHAR2(40) | sim | no SIH: 1=M, 3=F (difere do SIM) |
| `APGAR1` | VARCHAR2(40) | sim |  |
| `APGAR5` | VARCHAR2(40) | sim | Apgar no 5o minuto |
| `RACACOR` | VARCHAR2(40) | sim |  |
| `PESO` | VARCHAR2(40) | sim | peso ao nascer em gramas |
| `IDANOMAL` | VARCHAR2(40) | sim |  |
| `DTCADASTRO` | VARCHAR2(40) | sim |  |
| `CODANOMAL` | VARCHAR2(100) | sim |  |
| `NUMEROLOTE` | VARCHAR2(40) | sim |  |
| `VERSAOSIST` | VARCHAR2(40) | sim |  |
| `DTRECEBIM` | VARCHAR2(40) | sim |  |
| `DIFDATA` | VARCHAR2(40) | sim |  |
| `DTRECORIGA` | VARCHAR2(40) | sim |  |
| `NATURALMAE` | VARCHAR2(40) | sim |  |
| `CODMUNNATU` | VARCHAR2(40) | sim |  |
| `CODUFNATU` | VARCHAR2(40) | sim |  |
| `ESCMAE2010` | VARCHAR2(40) | sim |  |
| `SERIESCMAE` | VARCHAR2(40) | sim |  |
| `DTNASCMAE` | VARCHAR2(40) | sim |  |
| `RACACORMAE` | VARCHAR2(40) | sim |  |
| `QTDGESTANT` | VARCHAR2(40) | sim |  |
| `QTDPARTNOR` | VARCHAR2(40) | sim |  |
| `QTDPARTCES` | VARCHAR2(40) | sim |  |
| `IDADEPAI` | VARCHAR2(40) | sim |  |
| `DTULTMENST` | VARCHAR2(40) | sim |  |
| `SEMAGESTAC` | VARCHAR2(40) | sim |  |
| `TPMETESTIM` | VARCHAR2(40) | sim |  |
| `CONSPRENAT` | VARCHAR2(40) | sim |  |
| `MESPRENAT` | VARCHAR2(40) | sim |  |
| `TPAPRESENT` | VARCHAR2(40) | sim |  |
| `STTRABPART` | VARCHAR2(40) | sim |  |
| `STCESPARTO` | VARCHAR2(40) | sim |  |
| `TPNASCASSI` | VARCHAR2(40) | sim |  |
| `TPFUNCRESP` | VARCHAR2(40) | sim |  |
| `TPDOCRESP` | VARCHAR2(40) | sim |  |
| `DTDECLARAC` | VARCHAR2(40) | sim |  |
| `ESCMAEAGR1` | VARCHAR2(40) | sim |  |
| `STDNEPIDEM` | VARCHAR2(40) | sim |  |
| `STDNNOVA` | VARCHAR2(40) | sim |  |
| `CODPAISRES` | VARCHAR2(40) | sim |  |
| `TPROBSON` | VARCHAR2(40) | sim |  |
| `PARIDADE` | VARCHAR2(40) | sim |  |
| `KOTELCHUCK` | VARCHAR2(40) | sim |  |
| `CONTADOR` | VARCHAR2(40) | sim |  |

## SILVER

13 tabelas. 9.049.643 linhas.

### `SLV_DOM_COMPLEXIDADE`

**2 linhas · 2 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CODIGO` | VARCHAR2(2) | nao |  |
| `DESCRICAO` | VARCHAR2(30) | sim |  |

### `SLV_DOM_CONSULTAS_PRENATAL`

**4 linhas · 2 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CODIGO` | VARCHAR2(1) | nao |  |
| `DESCRICAO` | VARCHAR2(30) | sim |  |

### `SLV_DOM_GESTACAO`

**6 linhas · 4 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CODIGO` | VARCHAR2(1) | nao |  |
| `DESCRICAO` | VARCHAR2(40) | sim |  |
| `SEMANAS_MIN` | NUMBER | sim |  |
| `SEMANAS_MAX` | NUMBER | sim |  |

### `SLV_DOM_LOCAL_OBITO`

**6 linhas · 2 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CODIGO` | VARCHAR2(1) | nao |  |
| `DESCRICAO` | VARCHAR2(40) | sim |  |

### `SLV_DOM_SIH_CAR_INT`

**6 linhas · 2 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CODIGO` | VARCHAR2(2) | nao |  |
| `DESCRICAO` | VARCHAR2(80) | sim |  |

### `SLV_DOM_SIH_ESPEC`

**14 linhas · 2 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `CODIGO` | VARCHAR2(2) | nao |  |
| `DESCRICAO` | VARCHAR2(60) | sim |  |

### `SLV_ESTABELECIMENTO`

estabelecimentos tratados

**115.148 linhas · 8 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `COD_CNES` | VARCHAR2(40) | sim |  |
| `COD_MUNICIPIO` | NUMBER | sim |  |
| `COD_TIPO_UNIDADE` | VARCHAR2(40) | sim |  |
| `COD_GESTAO` | VARCHAR2(40) | sim |  |
| `COD_NATUREZA_JURIDICA` | VARCHAR2(40) | sim |  |
| `COD_NIVEL_HIERARQUIA` | VARCHAR2(40) | sim |  |
| `ATENDE_SUS` | NUMBER | sim |  |
| `REGSAUDE_CNES_NAO_CONFIAVEL` | VARCHAR2(40) | sim | mantido so como evidencia; nao usar para agregar |

### `SLV_INTERNACAO`

internacoes tratadas: datas em DATE, idade em anos, codigos resolvidos

**5.860.558 linhas · 28 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `NUM_AIH` | VARCHAR2(64) | sim |  |
| `COD_MUNIC_RESIDENCIA` | NUMBER | sim |  |
| `COD_MUNIC_INTERNACAO` | NUMBER | sim |  |
| `COD_CNES` | VARCHAR2(40) | sim |  |
| `DT_INTERNACAO` | DATE | sim |  |
| `DT_SAIDA` | DATE | sim |  |
| `ANO_COMPETENCIA` | NUMBER | sim |  |
| `MES_COMPETENCIA` | NUMBER | sim |  |
| `DIAS_PERMANENCIA` | NUMBER(19) | sim |  |
| `CID_PRINCIPAL` | VARCHAR2(40) | sim |  |
| `CID_CAPITULO` | VARCHAR2(4) | sim | primeira letra do CID-10 |
| `CID_SECUNDARIO` | VARCHAR2(40) | sim |  |
| `COD_PROCEDIMENTO` | VARCHAR2(52) | sim |  |
| `COD_ESPECIALIDADE` | VARCHAR2(40) | sim |  |
| `ESPECIALIDADE` | VARCHAR2(60) | sim |  |
| `COD_CARATER` | VARCHAR2(40) | sim |  |
| `CARATER_INTERNACAO` | VARCHAR2(80) | sim |  |
| `COD_COMPLEXIDADE` | VARCHAR2(40) | sim |  |
| `COMPLEXIDADE` | VARCHAR2(30) | sim |  |
| `SEXO` | CHAR(1) | sim | no SIH: 1=M, 3=F (difere do SIM) |
| `IDADE_ANOS` | NUMBER | sim | idade normalizada para anos, via COD_IDADE |
| `OBITO` | NUMBER | sim | flag 0/1 |
| `USOU_UTI` | NUMBER | sim | flag 0/1 |
| `DIARIAS_UTI` | NUMBER | sim |  |
| `VALOR_TOTAL` | NUMBER | sim |  |
| `VALOR_SERVICOS_HOSPITALARES` | NUMBER | sim |  |
| `VALOR_SERVICOS_PROFISSIONAIS` | NUMBER | sim |  |
| `INTERNOU_FORA_DO_MUNICIPIO` | NUMBER | sim | 1 quando residencia != internacao — insumo do IPA |

### `SLV_LEITO`

leitos tratados, por estabelecimento

**8.327 linhas · 9 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `COD_CNES` | VARCHAR2(40) | sim |  |
| `COD_MUNICIPIO` | NUMBER | sim |  |
| `COD_TIPO_LEITO` | VARCHAR2(40) | sim |  |
| `COD_LEITO` | VARCHAR2(40) | sim |  |
| `QTD_EXISTENTE` | NUMBER(19) | sim |  |
| `QTD_SUS` | NUMBER(19) | sim |  |
| `QTD_CONTRATADO` | NUMBER(19) | sim |  |
| `ANO_COMPETENCIA` | NUMBER | sim |  |
| `MES_COMPETENCIA` | NUMBER | sim |  |

### `SLV_MUNICIPIO`

dimensao territorial: nome, regiao de saude e coordenada

**3.473 linhas · 8 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `COD_MUNICIPIO` | NUMBER(6) | nao |  |
| `UF` | VARCHAR2(2) | sim |  |
| `REGIAO_SAUDE` | VARCHAR2(60) | sim | nome da regiao de saude, da Base Territorial do MS |
| `POPULACAO` | NUMBER | sim | PENDENTE — depende do IBGE |
| `COD_REGIAO_SAUDE` | VARCHAR2(5) | sim | CO_REGSAUD, codigo oficial de 5 digitos |
| `NOME_MUNICIPIO` | VARCHAR2(60) | sim | nome do municipio; o SIH so traz o codigo IBGE |
| `LATITUDE` | NUMBER(10,6) | sim | graus decimais, sede do municipio — para o mapa |
| `LONGITUDE` | NUMBER(10,6) | sim | graus decimais, sede do municipio — para o mapa |

### `SLV_NASCIMENTO`

nascimentos tratados, com indicadores derivados

**1.590.069 linhas · 18 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `COD_MUNIC_RESIDENCIA` | NUMBER | sim |  |
| `COD_MUNIC_NASCIMENTO` | NUMBER | sim |  |
| `DT_NASCIMENTO` | DATE | sim |  |
| `ANO_NASCIMENTO` | NUMBER | sim |  |
| `MES_NASCIMENTO` | NUMBER | sim |  |
| `PESO_GRAMAS` | NUMBER | sim |  |
| `BAIXO_PESO` | NUMBER | sim | 1 quando peso < 2500g |
| `COD_GESTACAO` | VARCHAR2(40) | sim |  |
| `FAIXA_GESTACAO` | VARCHAR2(40) | sim |  |
| `PREMATURO` | NUMBER | sim | 1 quando gestacao < 37 semanas |
| `COD_CONSULTAS_PRENATAL` | VARCHAR2(40) | sim |  |
| `CONSULTAS_PRENATAL` | VARCHAR2(30) | sim |  |
| `SEM_PRENATAL` | NUMBER | sim | 1 quando nenhuma consulta |
| `APGAR5` | NUMBER | sim | Apgar no 5o minuto |
| `IDADE_MAE` | NUMBER | sim |  |
| `MAE_ADOLESCENTE` | NUMBER | sim | 1 quando mae < 20 anos |
| `SEXO` | CHAR(1) | sim | no SIH: 1=M, 3=F (difere do SIM) |
| `COD_TIPO_PARTO` | VARCHAR2(40) | sim |  |

### `SLV_OBITO`

obitos tratados: data DDMMYYYY convertida, idade decodificada

**1.471.591 linhas · 11 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `COD_MUNIC_RESIDENCIA` | NUMBER | sim |  |
| `DT_OBITO` | DATE | sim |  |
| `ANO_OBITO` | NUMBER | sim |  |
| `MES_OBITO` | NUMBER | sim |  |
| `CID_CAUSA_BASICA` | VARCHAR2(40) | sim |  |
| `CID_CAPITULO` | VARCHAR2(4) | sim | primeira letra do CID-10 |
| `SEXO` | CHAR(1) | sim | no SIH: 1=M, 3=F (difere do SIM) |
| `IDADE_ANOS` | NUMBER | sim | idade normalizada para anos, via COD_IDADE |
| `COD_LOCAL_OCORRENCIA` | VARCHAR2(40) | sim |  |
| `LOCAL_OCORRENCIA` | VARCHAR2(40) | sim |  |
| `COD_RACA_COR` | VARCHAR2(40) | sim |  |

### `SLV_REGIAO_SAUDE`

as 439 regioes de saude do pais, 62 delas em SP

**439 linhas · 4 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `COD_REGIAO_SAUDE` | VARCHAR2(5) | nao | CO_REGSAUD, codigo oficial de 5 digitos |
| `NOME_REGIAO_SAUDE` | VARCHAR2(60) | nao | nome sem o sufixo ' - UF' que vem no arquivo original |
| `UF` | VARCHAR2(2) | sim |  |
| `ATIVA` | CHAR(1) | sim | S quando a regiao esta vigente (CO_STATUS) |

## GOLD

2 tabelas. 14.793 linhas.

### `GLD_FAIXA_RISCO`

limiares de classificacao de risco

**4 linhas · 6 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `NIVEL` | VARCHAR2(20) | nao |  |
| `ORDEM` | NUMBER(1) | sim |  |
| `IPA_MIN` | NUMBER(10,2) | sim |  |
| `IPA_MAX` | NUMBER(10,2) | sim |  |
| `COR` | VARCHAR2(7) | sim |  |
| `SEMAFORO` | VARCHAR2(10) | sim |  |

### `GLD_PAINEL_ASSISTENCIAL`

fato do painel: ano x mes x estabelecimento, com IPA e risco

**14.789 linhas · 12 colunas**

| Coluna | Tipo | Nulo | Significado |
|---|---|---|---|
| `ANO` | NUMBER(4) | nao |  |
| `MES` | NUMBER(2) | nao |  |
| `SIGLA_UF` | VARCHAR2(2) | sim |  |
| `ID_MUNICIPIO_ESTABELECIMENTO_AIH` | NUMBER(7) | sim | municipio do estabelecimento (= MUNIC_MOV) |
| `ID_ESTABELECIMENTO_CNES` | NUMBER(10) | nao |  |
| `INTERNACOES` | NUMBER | sim |  |
| `TOTAL_DIAS_PERMANENCIA` | NUMBER | sim |  |
| `PERMANENCIA_MEDIA` | NUMBER(10,2) | sim | total_dias_permanencia / internacoes |
| `CAPACIDADE_LEITOS` | NUMBER | sim | soma de QT_EXIST do CNES para o estabelecimento |
| `CUSTO_TOTAL` | NUMBER(14,2) | sim |  |
| `IPA_PERCENTUAL` | NUMBER(10,2) | sim | total_dias_permanencia / (capacidade_leitos * 30) * 100 |
| `RISCO_ASSISTENCIAL` | VARCHAR2(20) | sim | classificacao lida de GLD_FAIXA_RISCO |
