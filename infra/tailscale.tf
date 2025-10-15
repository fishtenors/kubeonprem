locals {
  tailscale_namespace = "tailscale"
}

# Manage Tailscale OAuth Client for Kubernetes Operator
resource "tailscale_oauth_client" "ts_client" {
  scopes = ["devices:core", "auth_keys"]
  tags   = ["tag:k8s-operator"]
}

# Install Tailscale on Kubernetes using Helm
resource "helm_release" "tailscale" {
  name       = "tailscale"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  namespace  = local.tailscale_namespace

  create_namespace = true

  set = [
    {
      name  = "oauth.clientId"
      value = tailscale_oauth_client.ts_client.id
    },
    {
      name  = "oauth.clientSecret"
      value = tailscale_oauth_client.ts_client.key
    }
  ]

  wait    = true
  timeout = 120

  depends_on = [kind_cluster.kop_cluster]
}

resource "null_resource" "ts_proxy_group" {
  provisioner "local-exec" {
    command = <<-EOT
        echo "Creating..."
        kubectl apply -f ${path.module}/configs/proxygroup-tailscale.yml -n ${local.tailscale_namespace} || true
      
        # Wait for proxy group to be ready
        kubectl wait proxygroup ts-proxies --for=condition=ProxyGroupReady=true -n ${local.tailscale_namespace} --timeout=60s || true
        echo "TS Proxy Group creation complete!"
    EOT
  }

  depends_on = [helm_release.tailscale]
}