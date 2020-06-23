#!/bin/sh

vault login $(consul kv get dc1-vault-cluster/root-token)
