# Infrastructure Setup: Kubernetes Cluster with Jenkins & Vault

This guide outlines the steps to:

- Create a Kubernetes cluster using Terraform
- Deploy Jenkins
- Deploy HashiCorp Vault
- Run service account token rotation using `sa_rotation.sh`

---

## 1. Create a Kubernetes Cluster with Terraform

Ensure you have the following prerequisites installed:

- Terraform
- kubectl
- Cloud provider CLI (e.g., AWS CLI, gcloud, az depending on the provider)

### Example for EKS on AWS

```bash
cd terraform/eks-cluster
terraform init
terraform apply
