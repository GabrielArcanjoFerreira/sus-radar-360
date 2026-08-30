# Conectar o Power BI

Windows, Power BI Desktop 64-bit. ~20 minutos, quase tudo instalação do cliente Oracle.

## O que o colega precisa receber

- O arquivo `Wallet_SUSRADAR.zip` — por canal privado, é credencial de rede
- A senha do usuário `GOLD` — peça ao responsável pelo banco, por canal privado. Não está neste repositório porque ele é público.
- Este arquivo

Não compartilhe a chave `.pem` da conta OCI — é credencial da nuvem inteira. A wallet basta.

## Passo a passo

- **Instale o Oracle Client for Microsoft Tools (OCMT), versão 64-bit.**
  `oracle.com/database/technologies/appdev/ocmt.html`
  O Power BI mostra a opção "Oracle Database" mesmo sem driver, e só falha ao conectar. Se instalar 32-bit, o erro é "provedor não instalado", que não menciona arquitetura.

- **Extraia a wallet em `C:\oracle\wallet\susradar`.**
  Devem aparecer 7 arquivos, entre eles `cwallet.sso`, `tnsnames.ora` e `sqlnet.ora`.

- **Edite o `sqlnet.ora` dessa pasta** para conter exatamente:
  ```
  WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="C:\oracle\wallet\susradar")))
  SSL_SERVER_DN_MATCH=yes
  ```

- **Defina o `TNS_ADMIN`** no PowerShell normal (não precisa de administrador):
  ```powershell
  [Environment]::SetEnvironmentVariable("TNS_ADMIN", "C:\oracle\wallet\susradar", "User")
  ```
  Confira com `[Environment]::GetEnvironmentVariable("TNS_ADMIN", "User")`.

- **Feche e reabra o Power BI.** Variável de ambiente só é lida quando o processo inicia.

- **Obter dados → Banco de dados → Oracle Database.** Preencha só:
  - Servidor: `susradar_medium`
  - Modo: Importar
  - Opções avançadas: vazio

- **Na tela de credenciais, clique em "Banco de Dados" no menu escuro à esquerda.**
  Ela abre na aba "Windows", que falha mesmo com usuário e senha certos.
  - Usuário: `GOLD`
  - Senha: peça ao responsável pelo banco

- **No Navegador, expanda `GOLD` e marque `VW_PAINEL_ASSISTENCIAL`.** Carregar.

## Se der erro

| Mensagem | Causa | Solução |
|---|---|---|
| `ORA-12154` | `TNS_ADMIN` não definido, ou Power BI não reiniciado | refaça os passos 4 e 5; teste `tnsping susradar_medium` |
| Não foi possível autenticar | você está na aba **Windows** | clique em **Banco de Dados** à esquerda |
| Provedor não instalado | OCMT ausente ou 32-bit | instale o OCMT 64-bit |
| `SecurityException` no PowerShell | usou escopo `"Machine"` sem elevação | troque por `"User"` |

Se o alias não for aceito, use o descritor completo no campo Servidor:

```
(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.us-ashburn-1.oraclecloud.com))(connect_data=(service_name=gd2dc045e9d5dd9_susradar_medium.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))
```

## Conferir que veio inteiro

- 14.789 linhas
- soma de `internacoes` = 5.860.558
- período 2024-06 a 2026-05
- 648 estabelecimentos

## Ao montar os visuais

- Use `ano` e `mes` como eixo do tempo, nunca uma data de internação.
- Filtre `ipa_percentual <= 100` nos rankings. 2,6% das linhas passam de 100% de ocupação por causa de hospitais de longa permanência cujo leito não está cadastrado na competência certa — sem o filtro, o "Top 10 CNES por IPA" mostra só esses artefatos.
