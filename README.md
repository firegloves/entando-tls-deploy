# entando-tls-deploy

This project eases the deploy of Entando 6.3.2 using TLS.

It has been created starting by this [tutorial](https://github.com/entando-k8s/entando-helm-quickstart/tree/v6.3.2).

It supports Vanilla Kubernetes, Openshift, Google Kubernetes.

## Before starting

You need to set a system environment variable named `HELM_QUICKSTART_PATH` that points to your local [entando-helm-quickstart](https://github.com/entando-k8s/entando-helm-quickstart/).

You need to set your kube context to point to the desired cluster.

## Instructions

To run the script you need to call `tls-deploy.sh` passing these required arguments:

- `-e` the target environment. Acceptable values are `kube` for vanilla Kubernetes, `oc` for RD, `gke` for Google Kubernetes
- `-n` the namespace where deploy the Entando instance
- `-u` the domain where Entando will be available, without the minor level

Examples:

- vanilla kubernetes in a Multipass VM (ip 192.168.64.5), using nip.io => `./tls-deploy.sh -e kube -u 192.168.64.5.nip.io -n fire`
- RD => `./tls-deploy.sh -e oc -u apps.rd.entando.org -n qe-one`
- GKE => `./tls-deploy.sh -e gke -u cluster-2.gke-ent.com -n my-namespace`

## Notes

At the end of the execution, you will find the generated cert files in the `cert` folder.
