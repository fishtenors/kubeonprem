locals {
  argocd_namespace = "argocd"
}

# Install ArgoCD
resource "null_resource" "argocd_install" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Installing ArgoCD..."
      kubectl create namespace ${local.argocd_namespace} || true
      kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -n ${local.argocd_namespace} || true
      
      # Wait for metrics server to be ready
      kubectl wait --for=condition=Available deployment argocd-server -n ${local.argocd_namespace} --timeout=60s || true
      echo "ArgoCD installation complete!"
    EOT
  }

  depends_on = [kind_cluster.kop_cluster]
}

# Generate an ssh key for ArgoCD to access Git repository
resource "tls_private_key" "argocd_deploy_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# Add the ssh key as a deploy key
resource "github_repository_deploy_key" "argocd_deploy_key" {
  title      = "ArgoCD Deploy Key"
  repository = var.github_repo_name
  key        = tls_private_key.argocd_deploy_key.public_key_openssh
  read_only  = false
}

# Create Kubernetes Secret for ArgoCD to access Git repository
resource "kubernetes_secret" "argocd_git_ssh" {
  metadata {
    name      = "argocd-git-ssh"
    namespace = local.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" : "repo-creds"
    }
  }

  data = {
    type          = "git"
    url           = "ssh://git@github.com/${var.github_owner}/${var.github_repo_name}.git"
    sshPrivateKey = tls_private_key.argocd_deploy_key.private_key_pem
  }

  depends_on = [null_resource.argocd_install, tls_private_key.argocd_deploy_key]
}

# Create Kubernetes Secret to access GitHub Container Registry
resource "kubernetes_secret" "kop_ghcr_secret" {
  metadata {
    name      = "kop-ghcr"
    namespace = "kop-app" # Secret will be used in the namespace where the application is deployed
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          "username" = var.github_owner
          "password" = var.github_token
          "auth"     = base64encode("${var.github_owner}:${var.github_token}")
        }
      }
    })
  }
}