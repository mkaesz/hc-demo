#!/bin/sh

VAULT_VERSION="1.4.2+ent"
cd /tmp/
curl https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip

sudo unzip vault.zip -d /usr/local/bin

vault -autocomplete-install
complete -C /usr/local/bin/vault vault
sudo rm -rf /tmp/vault.zip

sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

vault version

sudo mkdir -p /opt/vault/{config,data}
sudo chown -R hcops:hcops /opt/vault

cat <<-EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://vaultproject.io
Wants=network-online.target
After=network-online.target

[Service]
EnvironmentFile=/etc/environment
ExecReload=/bin/kill --signal HUP \$MAINPID
ExecStart=/usr/local/bin/vault \${VAULT_MODE} -config /opt/vault/config/config.hcl
KillMode=process
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
TasksMax=infinity
User=hcops
Group=hcops

[Install]
WantedBy=multi-user.target
EOF
