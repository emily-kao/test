#!/bin/sh

jx ns vault-infra

kubectl wait --for=condition=Ready pod/vault-0

kubectl port-forward service/vault 8200
