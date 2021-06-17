#!/bin/sh

printUsage() {
  echo "usage: $0 [-n namespace] [-e env] [-u url]"
  exit 1
}

checkArguments() {
  # namespace
  if [ -z "$namespace" ]; then
    echo '-n argument is required'
    printUsage
    exit 1
  fi

  if [ -z "$url" ]; then
    echo '-u argument is required'
    printUsage
    exit 1
  fi

  # env
  envAccepted=false
  for value in "${envArray[@]}"
  do
    [ "$env" = "$value" ] && envAccepted=true
  done
  if [ $envAccepted = "false" ] ; then
    envNotRecognized
  fi
}

envNotRecognized() {
  echo "Not recognized env received: ${env}. Allowed values are: ${envArray[*]}"
  printUsage
  exit 1
}

composeCaCertSecret() {
  crt=$(cat "${url}.crt" | base64)
  file="${url}-ca-cert-secrets.yml"
  sed -e "s/\[ns]/${namespace}/" -e "s/\[crt]/${crt}/" "${TEMPLATE_DIR}/ca-cert-secrets-template.yml" > "${file}"
  echo "${file}"
}

composeTlsSecrets() {
  key=$(cat "${url}.key" | base64)
  crt=$(cat "${url}.crt" | base64)
  file="${url}-tls-secrets.yml"
  sed -e "s/\[ns]/${namespace}/" -e "s/\[key]/${key}/" -e "s/\[crt]/${crt}/" "${TEMPLATE_DIR}/tls-secrets-template.yml" > "${file}"
  echo "${file}"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
envArray=("kube" "oc" "gke")

namespace=""
env=""
url=""

while getopts n:e:u: flag
do
  case "${flag}" in
      n) namespace=${OPTARG};;
      e) env=${OPTARG};;
      u) url=${OPTARG};;
      *) echo "usage: $0 [-n namespace] [-e env] [-u url]" >&2
         exit 1 ;;
  esac
done

checkArguments

echo "\n### namespace: ${namespace}"
echo "### env: ${env}"
echo "### url: ${url}"

kubectl delete ns "${namespace}"

set -e

case $env in

  kube)
    echo "\n### targeting environment Kubernetes"
    aioYaml="https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v6.3.2/manifests/k8s-116-and-later/namespace-scoped-deployment/cluster-resources.yaml"
    nsResources="${SCRIPT_DIR}/namespace-resources/kube-namespace-resources.yml"
    operatorConfigMap="${SCRIPT_DIR}/operator-config/kube-tls-entando-operator-config.yaml"
    ;;

  oc)
    echo "\n### targeting environment OpenShift"
    aioYaml="https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v6.3.2/manifests/k8s-before-116/namespace-scoped-deployment/cluster-resources.yaml"
    nsResources="${SCRIPT_DIR}/namespace-resources/oc-namespace-resources.yaml"
    operatorConfigMap="${SCRIPT_DIR}/operator-config/oc-tls-entando-operator-config.yaml"
    ;;

  gke)
    echo "\n### targeting environment GKE"
    aioYaml="https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v6.3.2/manifests/k8s-116-and-later/namespace-scoped-deployment/cluster-resources.yaml"
    nsResources="${SCRIPT_DIR}/namespace-resources/gke-namespace-resources.yaml"
    operatorConfigMap="${SCRIPT_DIR}/operator-config/gke-tls-entando-operator-config.yaml"
    ;;

  *)
    envNotRecognized
    ;;
esac

echo "\n### targeting namespace ${namespace}"

# GENERATE CERTS
cd "cert"
./generate-wildcard-certificate.sh "${url}"
caCertSecretFile=$(composeCaCertSecret)
tlsSecretFile=$(composeTlsSecrets)
echo "\n### certificate generated"

kubectl create ns "${namespace}"

kubectl apply -f "${aioYaml}"
echo "\n### clustered resources file applied"

kubectl apply -f "${nsResources}" -n "${namespace}"
echo "\n### namespaced resources file applied"

kubectl apply -f "${tlsSecretFile}" -n "${namespace}"
kubectl apply -f "${caCertSecretFile}" -n "${namespace}"
echo "\n### tls cert secrets applied"

kubectl apply -f "${operatorConfigMap}" -n "${namespace}"
echo "\n### operator config map applied"

cd "${HELM_QUICKSTART_PATH}"
helm template --namespace "${namespace}" --name=quickstart ./ | kubectl apply -n "${namespace}" -f -
echo "\n### helm template created and applied"


echo "\n### deploying... check the status"
