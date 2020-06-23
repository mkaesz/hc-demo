#!/bin/sh

if [[ ! -d "$NOMAD_TOKEN" ]]; then
  token=$(nomad acl bootstrap | grep Secret | awk '{print $4}')
  export NOMAD_TOKEN=$token
  echo "export NOMAD_TOKEN=$token" >> ~/.bashrc
  source ~/.bashrc
fi
