# Cluster Variables
variable "host_lb_http_port" {
  description = "Port for HTTP traffic to the load balancer"
  type        = number
  default     = 9080
}

variable "host_lb_https_port" {
  description = "Port for HTTPS traffic to the load balancer"
  type        = number
  default     = 9443
}

# Github Variables
variable "github_token" {
  description = "GitHub token for authentication"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub owner (user or organization)"
  type        = string
  default     = "ghuser"
}

variable "github_repo_name" {
  description = "Name of the GitHub repository"
  type        = string
  default     = "myrepo"
}

# Tailscale Variables
variable "tailscale_api_key" {
  description = "Tailscale API key for authentication"
  type        = string
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "Tailscale tailnet name"
  type        = string
  default     = "something.ts.net"
}