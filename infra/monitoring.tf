locals {
  monitoring_namespace = "monitoring"
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = local.monitoring_namespace

  create_namespace = true

  values = [
    file("${path.module}/configs/helm-prometheus.yml")
  ]

  # Wait for the deployment to be ready
  timeout = 300
  wait    = true

  depends_on = [kind_cluster.kop_cluster]
}

# resource "helm_release" "loki" {
#   name       = "loki"
#   repository = "https://grafana.github.io/helm-charts"
#   chart      = "loki"
#   namespace  = local.monitoring_namespace

#   create_namespace = false

#   # Don't wait for the deployment to be ready
#   wait = false

#   depends_on = [helm_release.prometheus]
# }

resource "null_resource" "prometheus_ingress" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Adding Prometheus Traefik ingress..."
      kubectl apply -f ${path.module}/configs/ingress-monitoring.yml -n ${local.monitoring_namespace} || true
    EOT
  }

  depends_on = [helm_release.prometheus]
}