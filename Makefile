# Variables
## NOTE: These are for convenience, and should not be changed
CLUSTER_NAME ?= kind-kop-cluster
APP_NS ?= kop-app
OBSERVE_NS ?= monitoring
TRAEFIK_NS ?= traefik
ARGOCD_NS ?= argocd
TAILSCALE_NS ?= tailscale
TAIL_NAME ?= mahi-crested.ts.net
TAIL_MACHINE_NAME ?= appkop

# Colors
GREEN := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RESET := $(shell tput -Txterm sgr0)

# Help Message
help: ## Show this help message
	@echo ""
	@echo "Usage:"
	@echo "  ${YELLOW}make${RESET} ${GREEN}<command>${RESET}"
	@echo ""
	@echo "Commands:"
	@echo "  ${YELLOW}check-deps: ${GREEN}Checks that required dependencies are installed${RESET}"
	@echo "  ${YELLOW}up: ${GREEN}Stands up kind cluster and application${RESET}"
	@echo "  ${YELLOW}down: ${GREEN}Shuts down and destroys kind cluster${RESET}"
	@echo "  ${YELLOW}terraform-init: ${GREEN}Perform a terraform init${RESET}"
	@echo "  ${YELLOW}terraform-plan: ${GREEN}Perform a terraform plan${RESET}"
	@echo "  ${YELLOW}terraform-apply: ${GREEN}Perform a terraform apply${RESET}"
	@echo "  ${YELLOW}argocd-init: ${GREEN}Initializes ArgoCD and bootstraps the github repository${RESET}"
	@echo "  ${YELLOW}argocd-dashboard: ${GREEN}Starts the ArgoCD admin dashboard${RESET}"
	@echo "  ${YELLOW}get-urls: ${GREEN}Output pertinent URLs${RESET}"
	@echo "  ${YELLOW}status: ${GREEN}Output cluster, application and ArgoCD statuses${RESET}"
	@echo ""

## Setup Commands
check-deps: ## Check if required dependencies are installed
	@echo "${GREEN}Checking dependencies...${RESET}"
	@command -v docker >/dev/null 2>&1 || { echo "docker is required but not installed. Aborting." >&2; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. Aborting." >&2; exit 1; }
	@command -v kind >/dev/null 2>&1 || { echo "kind is required but not installed. Aborting." >&2; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "terraform is required but not installed. Aborting." >&2; exit 1; }
	@command -v argocd >/dev/null 2>&1 || { echo "argocd is required but not installed. Aborting." >&2; exit 1; }
	@echo "${GREEN}All dependencies installed${RESET}"

up: check-deps ## Bootstrap the entire platform
	@echo "${GREEN} Bootstrapping GitOps Platform...${RESET}"
	@echo ""
	@echo "${YELLOW}==================================="
	@echo "NOTE: If this this fails on initial"
	@echo "run, simply run 'make up' again."
	@echo "===================================${RESET}"
	@echo ""
	@$(MAKE) terraform-apply
	@sleep 10
	@${MAKE} argocd-init
	@echo "${GREEN}Platform ready${RESET}"
	@$(MAKE) get-urls

down: ## Destroy the cluster and cleanup
	@echo "${YELLOW}Destroying cluster...${RESET}"
	@cd infra && terraform destroy --target github_repository_deploy_key.kop_deploy_key -auto-approve && terraform destroy --target kind_cluster.kop_cluster -auto-approve
	@echo "${YELLOW}Cleaning up Terraform files...${RESET}"
	@rm -rf infra/.terraform infra/.terraform.lock.hcl
	@rm -rf infra/terraform.tfstate*
	@rm -rf infra/kop-cluster-config
	@echo "${GREEN}Cluster destroyed${RESET}"
	@echo ""

## Terraform Commands
terraform-init: ## Initialize Terraform
	@echo "${GREEN}Initializing Terraform...${RESET}"
	@cd infra && terraform init -upgrade

terraform-plan: terraform-init ## Plan Terraform changes
	@cd infra && terraform plan

terraform-apply: terraform-init ## Apply Terraform configuration
	@echo "${GREEN}Creating cluster...${RESET}"
	@cd infra && terraform apply -auto-approve
	@echo "${GREEN}Cluster ready${RESET}"
	@echo ""

## ArgoCD Commands
argocd-init:
	@echo "${GREEN}Bootstrapping ArgoCD...${RESET}"
	@kubectl config set-context --current --namespace=argocd
	@argocd cluster add kind-kop-cluster
	@yes | argocd login --core
	@argocd app create -f gitops/gitops-repo.yml
	@echo "${GREEN}ArgoCD bootstrapped${RESET}"
	@echo ""

argocd-dashboard:
	@echo "${GREEN}Starting ArgoCD dashboard...${RESET}"
	@kubectl config set-context --current --namespace=argocd
	@argocd admin dashboard

## Information Commands
get-urls: ## Get application and service URLs
	@echo "${GREEN}===== URLs: =====${RESET}"
	@echo "App URL: http://${TAIL_MACHINE_NAME}.${TAIL_NAME}"
	@echo "Grafana URL: http://grafana.localhost:9080"
	@echo "Prometheus URL: http://prometheus.localhost:9080"
	@echo "Traefik URL: http://traefik.localhost:9080"
	@echo ""

status: ## Show cluster and application status
	@echo "${GREEN}Cluster Status:${RESET}"
	@echo ""
	@echo "----------------------------------------"
	@echo ""
	@kubectl cluster-info
	@echo ""
	@echo "----------------------------------------"
	@echo ""
	@echo "${GREEN}Nodes:${RESET}"
	@kubectl get nodes
	@echo ""
	@echo "----------------------------------------"
	@echo ""
	@echo "${GREEN}Namespaces:${RESET}"
	@kubectl get ns
	@echo ""
	@echo "----------------------------------------"
	@echo ""
	@echo "${GREEN}Application (${APP_NS}):${RESET}"
	@kubectl get all -n ${APP_NS}
	@echo ""
	@echo "----------------------------------------"
	@echo ""
	@echo "${GREEN}ArgoCD:${RESET}"
	@kubectl get applications -n ${ARGOCD_NS}
	@echo ""
