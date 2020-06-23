#!/bin/sh

nomad run postgres-nomad-demo.nomad

vault secrets enable database

vault write database/config/postgresql @connection.json

vault write database/roles/accessdb db_name=postgresql \
	creation_statements=@accessdb.sql default_ttl=1h max_ttl=24h

vault read database/creds/accessdb

vault policy write access-tables access-tables-policy.hcl

nomad run nomad-vault-demo.nomad
