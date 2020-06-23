#!/bin/sh

vault operator unseal $(consul kv get dc1-vault-cluster/unseal-key-1)
vault operator unseal $(consul kv get dc1-vault-cluster/unseal-key-2)
vault operator unseal $(consul kv get dc1-vault-cluster/unseal-key-3)
