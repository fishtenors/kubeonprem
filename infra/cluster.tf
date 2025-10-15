locals {
  # Globals
  cluster_name = "kop-cluster"
}

resource "kind_cluster" "kop_cluster" {
  name = local.cluster_name
  # node_image = "kindest/node:v1.34.0"
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Single control plan node
    node {
      role = "control-plane"

      # kubeadm_config_patches = [
      #   "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      # ]

      extra_port_mappings {
        container_port = 30080
        host_port      = var.host_lb_http_port
      }
      extra_port_mappings {
        container_port = 30443
        host_port      = var.host_lb_https_port
      }
    }

    # # Two worker nodes
    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }

  wait_for_ready = true

}

# Install Metrics Server
resource "null_resource" "metrics_server" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Installing Metrics Server..."
      kubectl apply -f ${path.module}/configs/metrics-server.yml || true
      
      # Wait for metrics server to be ready
      kubectl wait --for=condition=Available deployment metrics-server -n kube-system --timeout=60s || true
      echo "Metrics Server installation complete!"
    EOT
  }

  depends_on = [kind_cluster.kop_cluster]
}

# Create kop-app namespace
resource "null_resource" "kop_app_namespace" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating Application namespace..."
      kubectl create ns kop-app || true
    EOT
  }

  depends_on = [kind_cluster.kop_cluster]
}