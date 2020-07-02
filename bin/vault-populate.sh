#!/bin/sh

if [[ -z "$PIPELINE_GIT_TOKEN" ]]; then
    echo "PIPELINE_GIT_TOKEN is not defined for the pipeline bot user git token" 1>&2
    echo "" 1>&2
    echo "try the following first:" 1>&2
    echo "export PIPELINE_GIT_TOKEN="..."" 1>&2
    exit 1
fi
if [[ -z "$HMAC_TOKEN" ]]; then
    echo "HMAC_TOKEN is not defined for the lighthouse hmac token" 1>&2
    echo "" 1>&2
    echo "try the following first:" 1>&2
    echo "export HMAC_TOKEN="..."" 1>&2
    exit 1
fi

echo "make sure you are running ./bin/vault-port-forward.sh in another shell..."

export SECRET_DIR=/tmp/secrets/jx
mkdir -p $SECRET_DIR

jx ns vault-infra

export VAULT_TOKEN=$(kubectl get secrets vault-unseal-keys -o jsonpath={.data.vault-root} | base64 --decode)
kubectl get secret vault-tls -o jsonpath="{.data.ca\.crt}" | base64 --decode > $SECRET_DIR/vault-ca.crt

export VAULT_CACERT=$SECRET_DIR/vault-ca.crt
export VAULT_ADDR=https://127.0.0.1:8200

vault kv list secret

vault kv put secret/lighthouse/hmac token=$HMAC_TOKEN
vault kv put secret/jx/pipelineUser username=jenkins-x-labs-bot token=$PIPELINE_GIT_TOKEN

vault kv list secret
