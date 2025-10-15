# On-Prem GitOps App Platform

## Prerequisites
- Docker
- kubectl
- Helm
- terraform
- kind
- argocd
- make

## Getting Started
There are five variables that need to be set in order to stand the cluster up:

- github_token
- tailscale_api_key
- tailscale_tailnet
- github_owner
- github_repo_name

They can be declared in either of the following two ways:

*Option #1:* Create a `terraform.tfvars` file in the `infra/` directory, and populate it using the format: `key = "value"`. For example, `github_owner = "torvalds"`

*Option #2:* Export each variable using the format: ` export TF_VAR_key="value"` (Note the space before export, so as to not commit it to your terminal history). For example, ` export TF_VAR_github_owner = "torvalds"`

Once your variables are established, run `make up` from the root directory of this project.

## Considerations

### Platform
kind: Lightweight, good documentation, CLI very simple and intiutive, runs cross-platform. Functioning, maintained Terraform provider exists. k3d was the lightest and fastest, but I ran into 


### Ingress Controller
Traefik: This was a personal choice, as I have the most experience with it. 

### DNS & Certificates
Tailscale: Tunnel access, Magic DNS, and Certificate provisioning 

### GitOps
ArgoCD: 

### Observability
Prometheus with Grafana: 

## Notes
Researched and tested minikube, k3d and kind for local clustering. Found a few k3d providers in Terraform, but the most-used ones had not had updates in more than 2 years. The issue I had with 

Initially tried to make things dynamic and ultra-portable in Terraform, such as cluster name and namespaces, but this proved to be a pain due to a myriad of issues. 

Should I have used Ansible instead? Thought through inventory management and kubectl config context switching, and ultimately decided to stick with Terraform. I did find the k3s Ansible collection [here](https://github.com/k3s-io/k3s-ansible).