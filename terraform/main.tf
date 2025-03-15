terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

# Локальные переменные
locals {
  cluster_name = "${var.prefix}-cluster"
  tags = {
    Environment = var.environment
    Project     = "mini-linux-kubernetes"
    Terraform   = "true"
  }
}

# Выбор провайдера на основе переменной
provider "aws" {
  region = var.aws_region
  
  # Условное включение провайдера AWS
  count = var.cloud_provider == "aws" ? 1 : 0
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  
  # Условное включение провайдера GCP
  count = var.cloud_provider == "gcp" ? 1 : 0
}

provider "azurerm" {
  features {}
  
  # Условное включение провайдера Azure
  count = var.cloud_provider == "azure" ? 1 : 0
}

# Модули для разных облачных провайдеров

# AWS EKS кластер
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"
  
  # Условное создание EKS
  count = var.cloud_provider == "aws" ? 1 : 0
  
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  
  vpc_id     = var.aws_vpc_id
  subnet_ids = var.aws_subnet_ids
  
  eks_managed_node_groups = {
    default = {
      min_size     = var.min_nodes
      max_size     = var.max_nodes
      desired_size = var.desired_nodes
      
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"
    }
  }
  
  tags = local.tags
}

# GCP GKE кластер
resource "google_container_cluster" "gke" {
  # Условное создание GKE
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name     = local.cluster_name
  location = var.gcp_region
  
  # Мы создаем кластер с минимальным числом узлов
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "gke_nodes" {
  # Условное создание пула узлов GKE
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name       = "${local.cluster_name}-node-pool"
  cluster    = google_container_cluster.gke[0].name
  location   = var.gcp_region
  node_count = var.desired_nodes
  
  node_config {
    machine_type = var.node_instance_type
    
    # Метаданные Google Cloud
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    # Минимальные права доступа для Kubernetes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/compute",
    ]
  }
  
  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }
}

# Azure AKS кластер
resource "azurerm_resource_group" "aks_rg" {
  # Условное создание группы ресурсов Azure
  count = var.cloud_provider == "azure" ? 1 : 0
  
  name     = "${var.prefix}-rg"
  location = var.azure_location
  
  tags = local.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  # Условное создание AKS
  count = var.cloud_provider == "azure" ? 1 : 0
  
  name                = local.cluster_name
  location            = azurerm_resource_group.aks_rg[0].location
  resource_group_name = azurerm_resource_group.aks_rg[0].name
  dns_prefix          = "${var.prefix}-k8s"
  kubernetes_version  = var.kubernetes_version
  
  default_node_pool {
    name       = "default"
    node_count = var.desired_nodes
    vm_size    = var.node_instance_type
    enable_auto_scaling = true
    min_count  = var.min_nodes
    max_count  = var.max_nodes
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.tags
}
