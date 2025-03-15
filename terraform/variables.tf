variable "cloud_provider" {
  description = "Облачный провайдер для создания кластера (aws, gcp, azure)"
  type        = string
  default     = "aws"
}

variable "prefix" {
  description = "Префикс для всех ресурсов"
  type        = string
  default     = "mini-linux"
}

variable "environment" {
  description = "Окружение (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "Версия Kubernetes"
  type        = string
  default     = "1.26"
}

variable "min_nodes" {
  description = "Минимальное количество узлов"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Максимальное количество узлов"
  type        = number
  default     = 3
}

variable "desired_nodes" {
  description = "Желаемое количество узлов"
  type        = number
  default     = 2
}

variable "node_instance_type" {
  description = "Тип инстанса для узлов"
  type        = string
  default     = "t3.medium" # Для AWS
}

# AWS переменные
variable "aws_region" {
  description = "AWS регион"
  type        = string
  default     = "us-west-2"
}

variable "aws_vpc_id" {
  description = "ID VPC в AWS"
  type        = string
  default     = ""
}

variable "aws_subnet_ids" {
  description = "IDs подсетей в AWS"
  type        = list(string)
  default     = []
}

# GCP переменные
variable "gcp_project" {
  description = "ID проекта GCP"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "Регион GCP"
  type        = string
  default     = "us-central1"
}

# Azure переменные
variable "azure_location" {
  description = "Регион Azure"
  type        = string
  default     = "eastus"
}