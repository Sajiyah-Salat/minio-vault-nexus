```markdown
# Jenkins and MinIO Deployment Guide

This guide provides instructions to deploy MinIO, Jenkins, HC Vault, and Nexus using Kubernetes and Jenkins pipelines.

## Prerequisites

- Kubernetes cluster up and running
- `kubectl` installed and configured
- Jenkins deployed and accessible
- Service account and Docker image details available

---

## Configure Jenkins

1. Go to **Manage Jenkins** > **Add Cloud**.
2. Add a pod template with the service account name and the Docker image name provided in this repository.

---

## Create Pipelines

### MinIO Pipeline
1. Create a new pipeline in Jenkins.
2. Add the `minio-jenkinsfile` from this repository.
3. Run the pipeline.
4. Once successful, check the LoadBalancer URL for console access.
    - Username: `admin`
    - Password: `admin000`

### MinIO Bucket Migration
1. Create another pipeline in Jenkins.
2. Add the contents of `minio-bashscript-jenkinsfile` to the pipeline.
3. Click **Build with Parameters**, provide the required details, and run it.
4. This will copy all buckets from one MinIO instance to another.

---

## Deploy HC Vault

1. Create a new pipeline in Jenkins.
2. Add the contents of `hcvault-jenkinsfile` to the pipeline and run it.
3. Once deployed:
    - Initialize and unseal HC Vault by executing the following commands in the pod:
      ```bash
      vault operator init
      vault operator unseal
      ```

---

## Deploy Nexus

1. Create a new pipeline in Jenkins.
2. Add the contents of `nexus-jenkinsfile` to the pipeline and run it.
3. Once deployed:
    - Copy the ingress IP address.
    - Update your DNS name record with the ingress IP.

---

## Notes

- Ensure all required parameters are correctly configured in the pipelines.
- Refer to the respective `jenkinsfile` scripts in this repository for detailed configurations.
```
