<<<<<<< HEAD
# pattern-private-cluster
=======
# Pattern - Sample deployment of a private AKS cluster

This is a demo repo to deploy a private Azure Kubernetes Service cluster.

### Topology: 

 - [x] Private Cluster
 - [x] Kubenet
 - [x] Calico
 - [x] User Defined Routes
 - [x] Hub-Spoke Topology
 - [x] Jumpbox
 - [x] Azure Firewall
 
### Steps to run this demo

To install the full solution:

1. Run:

```bash
cd default
terraform init
terraform plan
terraform apply
```

1. Get the KUBECONFIG for the cluster and copy it into the jumpbox

```bash
terraform output -raw kubeconfig > config
```

You can retrieve the ssh user and fqdn for the jumpbox with this command:

```bash
terraform output -json  jumpbox | jq -r .ssh
```
>>>>>>> bde3f88 (Initial import)
