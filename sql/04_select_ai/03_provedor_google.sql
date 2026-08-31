-- PLANO B — Select AI com Gemini no lugar do OCI Generative AI.
--
-- Por que existe: a tenancy greatminds2026 tem cota ZERO no servico
-- ai-generative, entao o perfil SUSRADAR (provider oci) responde 404 em toda
-- chamada. Este arquivo troca o cerebro do Select AI por um provedor externo,
-- mantendo TUDO o mais igual — mesmas views, mesma camada semantica, mesma
-- sintaxe SELECT AI. So muda de onde vem o modelo de linguagem.
--
-- O Google AI Studio da chave gratuita com cota diaria, o que basta para
-- demonstrar e para o dia a dia do time. Pegue em https://aistudio.google.com/apikey
--
-- Os mesmos passos servem para openai e anthropic: muda o provider, o host da
-- ACL e o nome do modelo.

-- ---------------------------------------------------------------------------
-- PASSO 1 — como ADMIN: liberar o host do Google na ACL de rede.
-- ---------------------------------------------------------------------------
DECLARE
  PROCEDURE liberar(p_usuario VARCHAR2) IS
  BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
      host => 'generativelanguage.googleapis.com',
      ace  => xs$ace_type(privilege_list => xs$name_list('http', 'connect', 'resolve'),
                          principal_name => p_usuario,
                          principal_type => xs_acl.ptype_db));
  END;
BEGIN
  liberar('GOLD');
  liberar('ADMIN');
END;
/

-- ---------------------------------------------------------------------------
-- PASSO 2 — como GOLD: guardar a chave.
-- Trocar &&chave pela chave do AI Studio. Ela fica no banco como credencial,
-- nao em arquivo do repositorio.
-- ---------------------------------------------------------------------------
BEGIN
  DBMS_CLOUD.DROP_CREDENTIAL('GOOGLE_AI_CRED');
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'GOOGLE_AI_CRED',
    username        => 'GOOGLE',
    password        => '&&chave');
END;
/

-- ---------------------------------------------------------------------------
-- PASSO 3 — como GOLD: o perfil. object_list identico ao do perfil oci.
-- ---------------------------------------------------------------------------
BEGIN
  DBMS_CLOUD_AI.DROP_PROFILE(profile_name => 'SUSRADAR_GOOGLE', force => TRUE);
END;
/

BEGIN
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'SUSRADAR_GOOGLE',
    attributes   => '{
      "provider"        : "google",
      "credential_name" : "GOOGLE_AI_CRED",
      "model"           : "gemini-2.5-flash",
      "comments"        : "true",
      "conversation"    : "true",
      "object_list"     : [
        {"owner": "GOLD", "name": "VW_IPA_REGIAO"},
        {"owner": "GOLD", "name": "VW_PAINEL_REGIAO_MENSAL"},
        {"owner": "GOLD", "name": "VW_PAINEL_MUNICIPIO_MENSAL"},
        {"owner": "GOLD", "name": "VW_PAINEL_HOSPITAL"},
        {"owner": "GOLD", "name": "VW_MORBIDADE_REGIAO_MENSAL"},
        {"owner": "GOLD", "name": "VW_FLUXO_REGIAO"},
        {"owner": "GOLD", "name": "VW_VITAL_REGIAO_ANUAL"},
        {"owner": "GOLD", "name": "GLD_FAIXA_RISCO"}
      ]
    }');
END;
/

BEGIN
  DBMS_CLOUD_AI.SET_PROFILE('SUSRADAR_GOOGLE');
END;
/

-- ---------------------------------------------------------------------------
-- PASSO 4 — testar
-- ---------------------------------------------------------------------------
SELECT AI Quais regioes de SP estao em alerta vermelho;
