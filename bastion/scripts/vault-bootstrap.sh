#!/bin/sh

vault operator init | tee /tmp/vault.init > /dev/null

cnt=1
cat /tmp/vault.init | grep '^Unseal' | awk '{print $4}' | for key in $(cat -); do
        consul kv put dc1-vault-cluster/unseal-key-$cnt $key
        cnt=$((cnt + 1))
done

export ROOT_TOKEN=$(cat /tmp/vault.init | grep '^Initial' | awk '{print $4}')
consul kv put dc1-vault-cluster/root-token $ROOT_TOKEN

rm /tmp/vault.init

vault operator unseal $(consul kv get dc1-vault-cluster/unseal-key-1)
vault operator unseal $(consul kv get dc1-vault-cluster/unseal-key-2)
vault operator unseal $(consul kv get dc1-vault-cluster/unseal-key-3)

vault login $ROOT_TOKEN

#Master token for nomad servers
vault token create -id=3pa0NBHkh1e4tAlKQVMamsOz

vault write sys/license text=@vault-license.hclic

cd demo/nomad-bootstrap
vault policy write nomad-server nomad-server-policy.hcl
vault write /auth/token/roles/nomad-cluster @nomad-cluster-role.json
