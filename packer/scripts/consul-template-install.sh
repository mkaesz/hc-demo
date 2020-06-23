#!/bin/sh

CONSUL_TEMPLATE_VERSION="0.25.0"
cd /tmp

curl https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_arm64.zip -o consul-template.zip

unzip consul-template.zip -d /usr/local/bin

rm -rf /tmp/consul-template.zip

consul-template -version
