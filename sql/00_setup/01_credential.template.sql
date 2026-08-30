-- Credencial que o Autonomous Database usa para ler o Object Storage.
-- A autenticacao do OCI CLI NAO vale dentro do banco: ele precisa da sua propria.
--
-- ESTE ARQUIVO E UM TEMPLATE. Nunca preencha e commite.
-- Copie para fora do repo, preencha, rode, e apague a copia.
--
-- Rodar como o usuario BRONZE, nao como ADMIN.

-- ---------------------------------------------------------------------------
-- Opcao A (recomendada): chave API. Nao expira.
-- Os valores saem de ~/.oci/config; a private_key e o conteudo do .pem SEM as
-- linhas -----BEGIN/END----- e SEM quebras de linha.
-- ---------------------------------------------------------------------------
BEGIN
  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED_OCI',
    user_ocid       => '<ocid1.user.oc1..>',
    tenancy_ocid    => '<ocid1.tenancy.oc1..>',
    private_key     => '<conteudo do .pem em uma linha>',
    fingerprint     => '<xx:xx:xx:...>');
END;
/

-- ---------------------------------------------------------------------------
-- Opcao B: Auth Token. Mais simples de gerar (console > Profile > Auth Tokens),
-- mas e senha de usuario — trate como tal.
-- ---------------------------------------------------------------------------
-- BEGIN
--   DBMS_CLOUD.CREATE_CREDENTIAL(
--     credential_name => 'CRED_OCI',
--     username        => '<usuario da tenancy>',
--     password        => '<auth token>');
-- END;
-- /

-- Conferir (nao mostra segredo):
SELECT credential_name, username, enabled FROM user_credentials;
