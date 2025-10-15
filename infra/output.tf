# Outputs
output "cluster_name" {
  value       = local.cluster_name
  description = "Cluster name"
}

output "cluster_api_url" {
  value       = kind_cluster.kop_cluster.endpoint
  description = "Kubernetes API server URL"
}
