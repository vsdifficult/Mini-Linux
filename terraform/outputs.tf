output "cluster_id" {
  description = "ID кластера Kubernetes"
  value = var.cloud_provider == "aws" ? module.eks[0].cluster_id : (
    var.cloud_provider == "gcp" ? google_container_cluster.gke[0].id : (
      var.cloud_provider == "azure" ? azurerm_kubernetes_cluster.aks[0].id : ""
    )
  )
}

output "cluster_endpoint" {
  description = "Endpoint Kubernetes API"
  value = var.cloud_provider == "aws" ? module.eks[0].cluster_endpoint : (
    var.cloud_provider == "gcp" ? google_container_cluster.gke[0].endpoint : (
      var.cloud_provider == "azure" ? azurerm_kubernetes_cluster.aks[0].kube_config.0.host : ""
    )
  )
}

output "kubeconfig" {
  description = "Конфигурация kubeconfig для соединения с кластером"
  sensitive   = true
  
  value = var.cloud_provider == "aws" ? module.eks[0].kubeconfig : (
    var.cloud_provider == "gcp" ? {
      apiVersion = "v1"
      kind       = "Config"
      preferences = {}
      clusters = [{
        name    = google_container_cluster.gke[0].name
        cluster = {
          server                     = "https://${google_container_cluster.gke[0].endpoint}"
          certificate-authority-data = google_container_cluster.gke[0].master_auth.0.cluster_ca_certificate
        }
      }]
      users = [{
        name = "gcp"
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1beta1"
            command    = "gke-gcloud-auth-plugin"
          }
        }
      }]
      contexts = [{
        name    = google_container_cluster.gke[0].name
        context = {
          cluster = google_container_cluster.gke[0].name
          user    = "gcp"
        }
      }]
      current-context = google_container_cluster.gke[0].name
    } : (
      var.cloud_provider == "azure" ? azurerm_kubernetes_cluster.aks[0].kube_config_raw : ""
    )
  )
}