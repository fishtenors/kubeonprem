terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.2"
    }

    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.4"
    }

    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }

    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.22.0"
    }
  }
}

provider "null" {
  # Configuration options
}

provider "kubernetes" {
  # Configuration options
  config_path    = "~/.kube/config"
  config_context = "kind-${local.cluster_name}"
}

provider "helm" {
  # Configuration options
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "kind-${local.cluster_name}"
  }
}

provider "github" {
  # Configuration options
  token = var.github_token
  owner = var.github_owner
}

provider "tls" {
  # Configuration options
}

provider "tailscale" {
  # Configuration options
  api_key = var.tailscale_api_key
  tailnet = var.tailscale_tailnet
}