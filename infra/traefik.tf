locals {
  traefik_namespace = "traefik"
}

# Helm Install
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  namespace  = local.traefik_namespace

  create_namespace = true

  values = [
    file("${path.module}/configs/helm-traefik.yml")
  ]

  # Wait for the deployment to be ready
  timeout = 180
  wait    = true

  depends_on = [kind_cluster.kop_cluster]
}
