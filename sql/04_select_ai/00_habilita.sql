-- SELECT AI — habilitacao. Rodar UMA VEZ como ADMIN.
--
-- Sao quatro coisas, e faltando qualquer uma a chamada falha com um erro que nao
-- diz qual delas foi:
--   1. autenticacao por resource principal, para o banco se identificar na OCI
--      sem guardar chave de API;
--   2. EXECUTE em DBMS_CLOUD_AI para o usuario que vai criar o perfil;
--   3. ACL de rede liberando o host do provedor — sem ela da ORA-24247, e a ACL
--      vale por USUARIO, entao ADMIN tambem precisa da dele;
--   4. do lado da OCI, a policy susradar-adb-genai (ver docs/select-ai.md).

-- 1. resource principal
BEGIN
  DBMS_CLOUD_ADMIN.ENABLE_PRINCIPAL_AUTH(provider => 'OCI', username => 'GOLD');
END;
/

-- 2. o pacote
GRANT EXECUTE ON DBMS_CLOUD_AI TO gold;

-- 3. ACL de rede.
-- O host tem que ser o exato. O curinga '*.oraclecloud.com' NAO cobriu
-- inference.generativeai.us-ashburn-1.oci.oraclecloud.com, que tem quatro niveis
-- de subdominio — continuou dando ORA-24247 ate o host completo ser declarado.
DECLARE
  PROCEDURE liberar(p_host VARCHAR2, p_usuario VARCHAR2) IS
  BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
      host => p_host,
      ace  => xs$ace_type(privilege_list => xs$name_list('http', 'connect', 'resolve'),
                          principal_name => p_usuario,
                          principal_type => xs_acl.ptype_db));
  END;
BEGIN
  FOR u IN (SELECT 'GOLD' n FROM dual UNION ALL SELECT 'ADMIN' FROM dual) LOOP
    liberar('inference.generativeai.us-ashburn-1.oci.oraclecloud.com', u.n);
  END LOOP;
END;
/

-- Conferencia
SELECT host, principal, privilege FROM dba_host_aces
 WHERE principal IN ('GOLD', 'ADMIN') ORDER BY host, principal, privilege;
