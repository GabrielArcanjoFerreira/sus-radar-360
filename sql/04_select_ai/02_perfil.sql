-- PERFIL DO SELECT AI — SUSRADAR
-- Rodar como GOLD. Reexecutavel: apaga e recria o perfil.
--
-- Pre-requisitos, feitos uma vez como ADMIN em 00_habilita.sql:
--   ENABLE_PRINCIPAL_AUTH, GRANT EXECUTE ON DBMS_CLOUD_AI, ACL de rede.
-- E na OCI, a policy susradar-adb-genai.
--
-- ESTE PERFIL AINDA NAO RESPONDE NESTA TENANCY. Toda chamada volta 404 porque a
-- conta greatminds2026 tem cota ZERO em todos os limites do servico
-- ai-generative — Generative AI e servico pago e a conta nao tem direito a ele.
-- Nao e erro de configuracao: o mesmo 404 acontece pelo OCI CLI com usuario
-- Administrator. Detalhes, prova e as duas saidas em docs/select-ai.md.
-- Para demonstrar hoje, sem pagar, use 03_provedor_google.sql.
--
-- object_list e a lista fechada do que o modelo pode ver. Manter curta e de
-- proposito: cada objeto a mais entra no prompt, gasta contexto e da ao modelo
-- mais chance de escolher a tabela errada. Sao as 7 views da Gold mais a tabela
-- de faixas. Nada de Bronze e nada de Silver — dado cru com codigo do DATASUS
-- nao traduzido so produz resposta errada com cara de certa.

BEGIN
  DBMS_CLOUD_AI.DROP_PROFILE(profile_name => 'SUSRADAR', force => TRUE);
END;
/

BEGIN
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'SUSRADAR',
    attributes   => '{
      "provider"        : "oci",
      "credential_name" : "OCI$RESOURCE_PRINCIPAL",
      "region"          : "us-ashburn-1",
      "model"           : "meta.llama-4-maverick-17b-128e-instruct-fp8",
      "oci_apiformat"   : "GENERIC",
      "oci_compartment_id" : "ocid1.compartment.oc1..aaaaaaaasqcg57oac5npkryqnco5ofkb3a5eud3yj4looyaxqls5sjqfcjqq",
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

-- Deixa SUSRADAR como perfil da sessao. Sem isto toda chamada tem que dizer
-- qual perfil usar, e a sintaxe curta "SELECT AI <pergunta>" nao funciona.
BEGIN
  DBMS_CLOUD_AI.SET_PROFILE('SUSRADAR');
END;
/
