-- Tabelas de dominio da camada Silver.
-- Os microdados do DATASUS trazem tudo codificado; estas tabelas dao significado.
-- Fonte: dicionarios de variaveis da Transferencia de Arquivos (Modalidade Documentacao).

CREATE TABLE slv_dom_sih_espec (codigo VARCHAR2(2) PRIMARY KEY, descricao VARCHAR2(60));
INSERT ALL
  INTO slv_dom_sih_espec VALUES ('01','Cirurgia')
  INTO slv_dom_sih_espec VALUES ('02','Obstetricia')
  INTO slv_dom_sih_espec VALUES ('03','Clinica medica')
  INTO slv_dom_sih_espec VALUES ('04','Cronicos')
  INTO slv_dom_sih_espec VALUES ('05','Psiquiatria')
  INTO slv_dom_sih_espec VALUES ('06','Tisiologia')
  INTO slv_dom_sih_espec VALUES ('07','Pediatria')
  INTO slv_dom_sih_espec VALUES ('08','Reabilitacao')
  INTO slv_dom_sih_espec VALUES ('09','Hospital-dia cirurgicos')
  INTO slv_dom_sih_espec VALUES ('10','Hospital-dia AIDS')
  INTO slv_dom_sih_espec VALUES ('11','Hospital-dia fibrose cistica')
  INTO slv_dom_sih_espec VALUES ('12','Hospital-dia pos-transplante')
  INTO slv_dom_sih_espec VALUES ('13','Hospital-dia geriatria')
  INTO slv_dom_sih_espec VALUES ('14','Hospital-dia saude mental')
SELECT * FROM dual;

CREATE TABLE slv_dom_sih_car_int (codigo VARCHAR2(2) PRIMARY KEY, descricao VARCHAR2(80));
INSERT ALL
  INTO slv_dom_sih_car_int VALUES ('01','Eletivo')
  INTO slv_dom_sih_car_int VALUES ('02','Urgencia')
  INTO slv_dom_sih_car_int VALUES ('03','Acidente no local de trabalho')
  INTO slv_dom_sih_car_int VALUES ('04','Acidente no trajeto para o trabalho')
  INTO slv_dom_sih_car_int VALUES ('05','Outros acidentes de transito')
  INTO slv_dom_sih_car_int VALUES ('06','Outras lesoes e envenenamentos')
SELECT * FROM dual;

CREATE TABLE slv_dom_complexidade (codigo VARCHAR2(2) PRIMARY KEY, descricao VARCHAR2(30));
INSERT ALL
  INTO slv_dom_complexidade VALUES ('02','Media complexidade')
  INTO slv_dom_complexidade VALUES ('03','Alta complexidade')
SELECT * FROM dual;

CREATE TABLE slv_dom_gestacao (codigo VARCHAR2(1) PRIMARY KEY, descricao VARCHAR2(40), semanas_min NUMBER, semanas_max NUMBER);
INSERT ALL
  INTO slv_dom_gestacao VALUES ('1','Menos de 22 semanas', 0, 21)
  INTO slv_dom_gestacao VALUES ('2','22 a 27 semanas', 22, 27)
  INTO slv_dom_gestacao VALUES ('3','28 a 31 semanas', 28, 31)
  INTO slv_dom_gestacao VALUES ('4','32 a 36 semanas', 32, 36)
  INTO slv_dom_gestacao VALUES ('5','37 a 41 semanas', 37, 41)
  INTO slv_dom_gestacao VALUES ('6','42 semanas ou mais', 42, 45)
SELECT * FROM dual;

CREATE TABLE slv_dom_consultas_prenatal (codigo VARCHAR2(1) PRIMARY KEY, descricao VARCHAR2(30));
INSERT ALL
  INTO slv_dom_consultas_prenatal VALUES ('1','Nenhuma')
  INTO slv_dom_consultas_prenatal VALUES ('2','1 a 3 consultas')
  INTO slv_dom_consultas_prenatal VALUES ('3','4 a 6 consultas')
  INTO slv_dom_consultas_prenatal VALUES ('4','7 ou mais consultas')
SELECT * FROM dual;

CREATE TABLE slv_dom_local_obito (codigo VARCHAR2(1) PRIMARY KEY, descricao VARCHAR2(40));
INSERT ALL
  INTO slv_dom_local_obito VALUES ('1','Hospital')
  INTO slv_dom_local_obito VALUES ('2','Outro estabelecimento de saude')
  INTO slv_dom_local_obito VALUES ('3','Domicilio')
  INTO slv_dom_local_obito VALUES ('4','Via publica')
  INTO slv_dom_local_obito VALUES ('5','Outros')
  INTO slv_dom_local_obito VALUES ('6','Aldeia indigena')
SELECT * FROM dual;

COMMIT;
