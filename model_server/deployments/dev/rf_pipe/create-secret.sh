#!/usr/bin/env bash

# Set variables
if [[ -z ${WOS_AUTH_HEADER} ]]; then
  echo "Please provide environment variable WOS_AUTH_HEADER"
  exit 1
fi

WOS_AUTH_HEADER=${WOS_AUTH_HEADER}
SECRET_SUFFIX=${SECRET_SUFFIX:--rf-pipe}

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTOLLER_NAME=${SEALED_SECRET_CONTOLLER_NAME:-sealed-secrets}

# Create Kubernetes Secret yaml
oc create secret generic payload-collector-secrets${SECRET_SUFFIX} --type=Opaque \
--from-literal=WOS_AUTH_HEADER="${WOS_AUTH_HEADER}" \
--dry-run=client -o yaml > DELETE-payload-collector-secrets.yaml

# Encrypt the secret using kubeseal and private key from the cluster
kubeseal -n dev --controller-name=${SEALED_SECRET_CONTOLLER_NAME} --controller-namespace=${SEALED_SECRET_NAMESPACE} -o yaml < DELETE-payload-collector-secrets.yaml > DELETE-payload-collector-sealed-secret.yaml

# Remove suffix as Kustomize will add
yq '.metadata.name = "payload-collector-secrets"' < DELETE-payload-collector-sealed-secret.yaml > payload-collector-sealed-secret.yaml

# NOTE, do not check DELETE-*.yaml files into git!
rm DELETE-*.yaml