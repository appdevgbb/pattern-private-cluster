# Pattern - Private AKS Cluster with Cloud Shell Integration

This repository contains Terraform configuration to deploy a private Azure Kubernetes Service (AKS) cluster with Cloud Shell VNet integration for secure access.

## Topology

- [x] Private AKS Cluster with API Server VNet Integration
- [x] Azure CNI Overlay networking
- [x] Standard Load Balancer
- [x] Private DNS zones (AKS API, Storage, Relay)
- [x] User-assigned managed identity
- [x] Cloud Shell infrastructure with VNet integration
- [x] Azure Relay with private endpoint
- [x] Storage account with Azure AD authentication (no shared keys)
- [x] Private endpoints for all services
- [x] Network Security Groups for Cloud Shell

## Cluster Configuration

- **Kubernetes Version**: 1.32.9
- **Network Plugin**: Azure CNI Overlay
- **Network Mode**: Overlay
- **Pod CIDR**: 10.244.0.0/16
- **Service CIDR**: 10.0.0.0/16
- **DNS Service IP**: 10.0.0.10
- **Private Cluster**: Enabled with VNet Integration
- **API Server Subnet**: 10.1.2.0/24
- **Node Subnet**: 10.1.1.0/24
- **Private FQDN**: pvt-example-zjte58so.c5dd28a6-e22c-45f1-8bda-cced0f182bd4.private.westus3.azmk8s.io

## Network Architecture

The deployment creates a single VNet (10.1.0.0/16) with the following subnets:

- **aks-subnet** (10.1.1.0/24) - AKS node pool
- **api-server-subnet** (10.1.2.0/24) - AKS API server VNet integration
- **cloudshellsubnet** (10.1.3.0/24) - Cloud Shell containers (delegated to Microsoft.ContainerInstance/containerGroups)
- **relaysubnet** (10.1.4.0/24) - Azure Relay private endpoint
- **storagesubnet** (10.1.5.0/24) - Storage account private endpoints

## Prerequisites

- Azure CLI logged in (`az login`)
- Terraform >= 1.11.4
- AzureRM Provider >= 4.54.0
- Subscription with appropriate permissions for:
  - Creating managed identities
  - Deploying AKS clusters
  - Creating private endpoints
  - Configuring Cloud Shell

## Deployment Steps

1. Navigate to the default directory and copy the example tfvars:

```bash
cd default
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` to customize values (cluster name, storage account name, relay namespace name, etc.)

3. Initialize and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

4. Activate Cloud Shell with VNet integration:
   - Open Azure Portal
   - Click on Cloud Shell icon
   - Click **Configure** button
   - Select the existing resources:
     - Storage account: `csshellstorage<random>`
     - File share: `acsshare`
     - Relay namespace: `arn-cloudshell-westus3`
     - Network profile: `aci-networkProfile-westus3`
   - Cloud Shell will deploy a container instance in the `cloudshellsubnet`

5. Access the private cluster from Cloud Shell:

```bash
# Get cluster credentials
az aks get-credentials --resource-group rg-private-cluster --name private-cluster

# Verify connectivity
kubectl get nodes
kubectl cluster-info
```

## Configuration Details

The deployment creates:
- **Resource Group**: `rg-private-cluster`
- **Virtual Network**: `vnet-private-cluster` (10.1.0.0/16)
- **AKS Cluster**: `private-cluster` (Kubernetes 1.32)
- **System node pool**: 1 node (Standard_DS2_v2)
- **Storage Account**: Azure AD authentication only (shared access keys disabled)
- **File Share**: 50 GB quota for Cloud Shell
- **Azure Relay**: Private endpoint connectivity for Cloud Shell
- **Network Profile**: Container network interface for Cloud Shell

To customize, modify variables in `terraform.tfvars`.

## Outputs

- `resource_group_name` - The resource group name
- `cluster_name` - The AKS cluster name
- `cloudshell_storage_account_name` - Storage account for Cloud Shell
- `cloudshell_relay_namespace_name` - Azure Relay namespace for Cloud Shell
- `cloudshell_container_subnet_id` - Subnet ID for Cloud Shell containers
- `kubeconfig` - The cluster credentials (sensitive)

## Important Notes

### Storage Account Security
The storage account is configured with:
- **Azure AD authentication only** (`shared_access_key_enabled = false`)
- **Private endpoints only** (`public_network_access_enabled = false`)
- Terraform provider setting: `storage_use_azuread = true` (required in provider block)

### Private Cluster Access
Since this is a private cluster with API server VNet integration:
- **Direct kubectl access** requires network connectivity to the VNet
- **Cloud Shell with VNet integration** provides secure access from the same VNet
- **Alternative**: Use `az aks command invoke` for one-off commands without VNet connectivity

### Cloud Shell Activation
The Terraform deployment creates all infrastructure components, but Cloud Shell requires one-time Portal activation:
1. Infrastructure (Terraform) - VNet, subnets, storage, relay, network profile, DNS zones ✅
2. Service Activation (Portal) - Click "Configure" to deploy the actual container instance

## Troubleshooting

### kubectl Connection Errors
If you see connection timeouts or errors like:
```
Unable to connect to the server: dial tcp: lookup <fqdn> on 168.63.129.16:53: no such host
```
This is expected when accessing from outside the VNet. Use Cloud Shell with VNet integration or `az aks command invoke`.

### Storage Account Access Denied
If Terraform fails with "Key based authentication is not permitted":
- Ensure `storage_use_azuread = true` is set in the provider block
- The subscription may have Azure Policy enforcing Azure AD authentication

## Cleanup

To destroy all resources:

```bash
terraform destroy -auto-approve
```