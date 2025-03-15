# Kubernetes Mini Linux Deployment

This repository contains code for creating a Kubernetes cluster and running a minimal Linux (Alpine) container in it.

## Repository Structure

```
.
├── README.md                    # Usage instructions
├── terraform/                   # Code for creating Kubernetes cluster
│   ├── main.tf                  # Main Terraform configuration file
│   ├── variables.tf             # Configuration variables
│   └── outputs.tf               # Output values for use after deployment
├── kubernetes/                  # Kubernetes manifests
│   └── mini-linux-deployment.yaml  # Manifest for running a mini-Linux container
└── docker/                      # Files for building container image
    └── Dockerfile               # Definition of mini-Linux image
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (version >= 1.0.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)
- Cloud provider account (AWS, GCP, or Azure)

## Step-by-Step Instructions

### 1. Creating a Kubernetes Cluster

1. Navigate to the `terraform` directory:
   ```bash
   cd terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Configure variables in the `terraform.tfvars` file or use environment variables.

4. Create an execution plan:
   ```bash
   terraform plan -out=plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply plan
   ```

6. After completion, get the configuration for accessing the cluster:
   ```bash
   terraform output kubeconfig > ~/.kube/config
   ```

### 2. Building and Uploading the Docker Image

1. Navigate to the `docker` directory:
   ```bash
   cd ../docker
   ```

2. Build the Docker image:
   ```bash
   docker build -t mini-linux:latest .
   ```

3. Push the image to a registry (e.g., Docker Hub):
   ```bash
   docker tag mini-linux:latest yourusername/mini-linux:latest
   docker push yourusername/mini-linux:latest
   ```

### 3. Running the Container in Kubernetes

1. Navigate to the `kubernetes` directory:
   ```bash
   cd ../kubernetes
   ```

2. Open the `mini-linux-deployment.yaml` file and update the image reference if necessary.

3. Apply the manifest to create the deployment:
   ```bash
   kubectl apply -f mini-linux-deployment.yaml
   ```

4. Check the deployment status:
   ```bash
   kubectl get pods
   ```

## Configurations for Different Cloud Providers

The repository supports three major cloud providers. To select a provider, set the `cloud_provider` variable in the `terraform.tfvars` file.

## Additional Information

To access the mini-Linux container console, use:
```bash
kubectl exec -it $(kubectl get pod -l app=mini-linux -o jsonpath="{.items[0].metadata.name}") -- /bin/sh
```