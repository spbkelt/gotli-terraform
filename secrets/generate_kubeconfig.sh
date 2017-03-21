#!/bin/bash

set -e

while getopts ":u:k:r:a:c:t:" opt; do
  case $opt in
    u) KUBE_USER="$OPTARG";;
    k) KUBE_CONFIG="$OPTARG";;
    r) REGION="$OPTARG";;
    a) KUBE_API_URL="$OPTARG";;
    c) CA_PATH="$OPTARG";;
    t) TOKEN="$OPTARG";;
  esac
done

if [[ -z "${TOKEN}" || -z "${KUBE_USER}" ]];then
        echo "no $KUBE_USER or secret token provided"
        exit 1
fi

kubectl config set-cluster "${REGION}" --server="${KUBE_API_URL}" --certificate-authority="${CA_PATH}" --kubeconfig "${KUBE_CONFIG}"
kubectl config set-credentials "${KUBE_USER}"  --token "${TOKEN}" --kubeconfig "${KUBE_CONFIG_URL}"
kubectl config set-context "${REGION}" --cluster="${REGION}" --namespace=kube-system --user="${KUBE_USER}" --kubeconfig "${KUBE_CONFIG}"
kubectl config use-context "${REGION}" --kubeconfig "${KUBE_CONFIG}"
