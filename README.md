# entando-tls-deploy

This project eases the deployment of Entando 6.3.2 using TLS.

It has been created starting with this [tutorial](https://github.com/entando-k8s/entando-helm-quickstart/tree/v6.3.2).

It supports Vanilla Kubernetes, Openshift, Google Kubernetes.

## Prerequisites

You need to set a system environment variable named `HELM_QUICKSTART_PATH` that points to your local [entando-helm-quickstart](https://github.com/entando-k8s/entando-helm-quickstart/).

You need to set your kubernetes context to point to the desired cluster.

If you want to set components images version, you can find them in `namespace-resources/*-namespace-resources.yml` files. 

## Instructions

### Step 1

To run the script you need to call `tls-deploy.sh` passing these required arguments:

- `-e` the target environment. Acceptable values are
  - `kube` for vanilla Kubernetes (Kubernetes >= v1.16)
  - `oc` for RD (Kubernetes < v1.16)
  - `gke` for Google Kubernetes (Kubernetes >= v1.16)
- `-n` the namespace where deploy the Entando instance
- `-u` the domain where Entando will be available

Examples:

- vanilla kubernetes in a Multipass VM (ip 192.168.64.5), using nip.io => `./tls-deploy.sh -e kube -u 192.168.64.5.nip.io -n fire`
- RD => `./tls-deploy.sh -e oc -u apps.rd.entando.org -n qe-one`
- GKE => `./tls-deploy.sh -e gke -u cluster-2.gke-ent.com -n my-namespace`

### Step 2

Create the app with this addition to the manifest file or simply add the `APPLICATIONBASEURL` environment variable.
Replace the `{HOSTNAME}` placeholder with the desired value. 

```
kind: EntandoCompositeApp
spec:
components:
- kind: EntandoKeycloakServer
  spec:
  environmentVariables:
  - name: APPLICATIONBASEURL
  value: https://{HOSTNAME}/entando-de-app/
```

### Step 3

In AppBuilder under `Pages/Settings` set:

`Base URL` to `Static`

## Notes

At the end of the execution, you will find the generated cert files in the `cert` folder.
