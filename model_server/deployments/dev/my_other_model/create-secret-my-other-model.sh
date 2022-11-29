#!/usr/bin/env bash

# Set variables
if [[ -z ${CPD_USER} ]]; then
  echo "Please provide environment variable CPD_USER"
  exit 1
fi

if [[ -z ${CPD_PASSWORD} ]]; then
  echo "Please provide environment variable CPD_PASSWORD"
  exit 1
fi

CPD_USER=${CPD_USER}
CPD_PASSWORD=${CPD_PASSWORD}
SECRET_SUFFIX=${SECRET_SUFFIX:--rf-pipe}

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTOLLER_NAME=${SEALED_SECRET_CONTOLLER_NAME:-sealed-secrets}

# Create Kubernetes Secret yaml
oc create secret generic my-other-model-secrets${SECRET_SUFFIX} --type=Opaque \
--from-literal=CPD_USER="${CPD_USER}" \
--from-literal=CPD_PASSWORD="${CPD_PASSWORD}" \
--dry-run=client -o yaml > DELETE-my-other-model-secrets.yaml

# Encrypt the secret using kubeseal and private key from the cluster
kubeseal -n dev --controller-name=${SEALED_SECRET_CONTOLLER_NAME} --controller-namespace=${SEALED_SECRET_NAMESPACE} -o yaml < DELETE-my-other-model-secrets.yaml > DELETE-my-other-model-sealed-secret.yaml

# Remove suffix as Kustomize will add
yq '.metadata.name = "rf-pipe-secrets"' < DELETE-my-other-model-sealed-secret.yaml > my-other-model-sealed-secret.yaml

# NOTE, do not check DELETE-*.yaml files into git!
rm DELETE-*.yaml