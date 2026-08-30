#!/usr/bin/env python3
"""
Cria a credencial DBMS_CLOUD que o Autonomous Database usa para ler o Object
Storage. A chave privada e lida de ~/.oci/oci_api_key.pem e passada como bind
variable — nunca vai para arquivo, log ou terminal.

  .venv/bin/python scripts/criar_credencial.py
"""
import re, sys
from pathlib import Path
import importlib.util

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("db", ROOT / "scripts" / "db.py")
db = importlib.util.module_from_spec(spec); spec.loader.exec_module(db)

cfg_oci = {}
for l in Path.home().joinpath(".oci", "config").read_text().splitlines():
    if "=" in l and not l.strip().startswith(("[", "#")):
        k, v = l.split("=", 1); cfg_oci[k.strip()] = v.strip()

pem = Path(cfg_oci["key_file"]).read_text()
# DBMS_CLOUD quer o corpo da chave sem cabecalho/rodape e sem quebras de linha
corpo = re.sub(r"-----(BEGIN|END)[^-]+-----", "", pem).replace("\n", "").replace("\r", "").strip()
if not corpo:
    sys.exit("[ERRO] chave privada vazia")

con = db.conectar("bronze")
try:
    with con.cursor() as cur:
        cur.execute("""
            BEGIN
              BEGIN DBMS_CLOUD.DROP_CREDENTIAL('CRED_OCI');
              EXCEPTION WHEN OTHERS THEN NULL; END;
              DBMS_CLOUD.CREATE_CREDENTIAL(
                credential_name => 'CRED_OCI',
                user_ocid       => :u,
                tenancy_ocid    => :t,
                private_key     => :k,
                fingerprint     => :f);
            END;""",
            u=cfg_oci["user"], t=cfg_oci["tenancy"], k=corpo, f=cfg_oci["fingerprint"])
    con.commit()
    with con.cursor() as cur:
        cur.execute("SELECT credential_name, username, enabled FROM user_credentials")
        for r in cur:
            print("credencial:", r[0], "| enabled:", r[2])
finally:
    con.close()
