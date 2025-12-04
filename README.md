# Pattern - Private AKS Cluster Deployment

This repository contains Terraform configuration to deploy a private Azure Kubernetes Service (AKS) cluster.

## Topology

- [x] Private AKS Cluster
- [x] Azure CNI networking
- [x] Calico network policy
- [x] Standard Load Balancer
- [x] Private DNS zone for cluster API
- [x] User-assigned managed identity
- [x] Single VNet topology

## Prerequisites

- Azure CLI logged in (`az login`)
- Terraform >= 1.11.4

## Deployment Steps

1. Set the required environment variable:

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

2. Initialize and apply the Terraform configuration:

```bash
cd default
terraform init
terraform plan
terraform apply -auto-approve
```

3. Get the kubeconfig for the cluster:

```bash
terraform output -raw kubeconfig > kubeconfig
export KUBECONFIG=$PWD/kubeconfig
```

4. Verify cluster access:

```bash
kubectl get nodes
```

## Configuration

The deployment creates:
- Resource Group: `rg-demo-gbb`
- Virtual Network: `pvt-vnet` (10.220.0.0/16)
- AKS Cluster: `pvt-cluster` (Kubernetes 1.31)
- System node pool: 2-3 nodes (auto-scaling)
- User node pool: 1 node

To customize, modify variables in `terraform.tfvars` or update the default values in `000-variables.tf`.

## Outputs

- `resource_group_name` - The resource group name
- `aks_cluster_name` - The AKS cluster name
- `aks_managed_id` - The managed identity details
- `kubeconfig` - The cluster credentials (sensitive)

## Cleanup

To destroy all resources:

```bash
terraform destroy -auto-approve
```