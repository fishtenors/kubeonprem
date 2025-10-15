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

Once your variables are established, run `make up` from the root directory of this project. For additional Makfile help, run `make help`.

## Considerations

### Platform
kind: Lightweight, good documentation, CLI very simple and intiutive, runs cross-platform. Functioning, maintained Terraform provider exists. k3d was the lightest and fastest, and minikube was heaviest. I decided on kind as it was somewhere in the middle, performance-wise, had a decent Terraform provider, and community support was strong. The biggest pain was that kind does not include metric-server, which is necessary for autoscaling and observability.


### Ingress Controller
Traefik: This was a personal choice, as I have the most experience with it. Relatively simple to stand up with Helm, and I find the way that IngressRoute match patterns are setup to be very intuitive. Additionally, it has a decent ACME cert provisioner capability that I've used in the past, even though I ended up not using it in favor of...

### DNS & Certificates
Tailscale: Tunnel access, Magic DNS, and Certificate provisioning. I have extensive experience with Twingate, and this is a striong competitor. Great Terraform support, and the Kubernetes Operator installation was very well documented. The Funnel capability made it very easy to expose the app and provision a certificate. If I needed a deeper certificate solution, I was ready to stand up cert-manager or use Traefik. 

### GitOps
ArgoCD: Very mature gitops platform. The core installation is very similar to FluxCD, but comes with a very nice UI to visually see where all deployments are at. IMO, Flux has superior documentation and Terraform support, but ArgoCD is more flexible, intuitive, and operator-friendly.

### Observability
Prometheus with Grafana: Very mature tool set and Helm chart. Took a bit of research and massaging to get Prometheus to scrape services in the other namespaces

## Other Notes
Researched and tested minikube, k3d and kind for local clustering. Found a few k3d providers in Terraform, but the most-used ones had not had updates in more than 2 years.

Initially tried to make things dynamic and ultra-portable in Terraform, such as cluster name and namespaces, but this proved to be a pain.

Should I have used Ansible instead? Thought through inventory management and kubectl config context switching, and ultimately decided to stick with Terraform. I did find the k3s Ansible collection [here](https://github.com/k3s-io/k3s-ansible).