-- Usuarios das camadas. Rodar como ADMIN, uma vez.
-- Nao usar ADMIN para os dados: as permissoes espelham o medallion.

CREATE USER bronze IDENTIFIED BY "&bronze_pwd" QUOTA UNLIMITED ON DATA;
GRANT DWROLE TO bronze;
GRANT EXECUTE ON DBMS_CLOUD TO bronze;   -- sem isso, External Table falha com ORA-00942

CREATE USER silver IDENTIFIED BY "&silver_pwd" QUOTA UNLIMITED ON DATA;
GRANT DWROLE TO silver;
GRANT CREATE VIEW, CREATE MATERIALIZED VIEW TO silver;

-- silver le a bronze
BEGIN
  FOR t IN (SELECT table_name FROM all_tables WHERE owner = 'BRONZE') LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON bronze.' || t.table_name || ' TO silver';
  END LOOP;
END;
/
