CURRENT_DIR=$(shell pwd)
GENERATED_DIR=$(CURRENT_DIR)/generated
PARAMETERS_FILE?=parameters.tfvars
STATE_FILE=metrics-server-terraform.tfstate
OUTPUT_FILE=$(GENERATED_DIR)/metrics-server-output.json
MODULES_DIR?=$(GENERATED_DIR)/infra-modules
MODULES_SOURCE=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_images.infra[0]')
MODULES_VERSION=$(shell cat $(VERSIONS_FILE) | jq -r '.armonik_versions.infra')
TERRAFORM_PLUGINS?=$(GENERATED_DIR)/terraform-plugins

export TF_DATA_DIR?=$(GENERATED_DIR)
export TF_PLUGIN_CACHE_DIR?=$(TERRAFORM_PLUGINS)
export REGION?=eu-west-3
export PROFILE?=default
export NAMESPACE?=kube-system
export SUFFIX?=main
export AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query "Account" --output text)
export TFSTATE_BUCKET_NAME?=armonik-tfstate-$(SUFFIX)
export KUBECONFIG?=$(GENERATED_DIR)/eks/kubeconfig

.PHONY: apply destroy

all: get-modules init apply output
deploy: get-modules init apply output
destroy: init delete

init:
	mkdir -p $(TF_PLUGIN_CACHE_DIR)
	mkdir -p $(GENERATED_DIR)
	terraform init -upgrade \
		-backend-config 'bucket=$(TFSTATE_BUCKET_NAME)' \
		-backend-config 'region=$(REGION)' \
		-backend-config 'key=$(STATE_FILE)' \
		-backend-config 'profile=$(PROFILE)'

apply:
	terraform apply \
		-var-file $(PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'profile=$(PROFILE)' \
		-var 'namespace=$(NAMESPACE)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'aws_account_id=$(AWS_ACCOUNT_ID)' \
		-var 'k8s_config_path=$(KUBECONFIG)' \
		-state $(STATE_FILE) \
		-auto-approve

output:
	@echo -n "{\"metrics_server\":" > $(OUTPUT_FILE)
	@terraform output -state=$(STATE_FILE) -json metrics_server >> $(OUTPUT_FILE)
	@echo -n "}" >> $(OUTPUT_FILE)
	@echo "\nOUTPUT FILE: $(OUTPUT_FILE)"

delete:
	terraform destroy \
		-var-file $(PARAMETERS_FILE) \
		-var 'region=$(REGION)' \
		-var 'profile=$(PROFILE)' \
		-var 'namespace=$(NAMESPACE)' \
		-var 'suffix=$(SUFFIX)' \
		-var 'aws_account_id=$(AWS_ACCOUNT_ID)' \
		-var 'k8s_config_path=$(KUBECONFIG)' \
		-state $(STATE_FILE) \
		-auto-approve

get-modules:
	@if [ -d $(MODULES_DIR) ]; then\
		git -C $(MODULES_DIR) fetch --all --tags;\
		git -C $(MODULES_DIR) -c advice.detachedHead=false checkout $(MODULES_VERSION);\
		git -C $(MODULES_DIR) pull origin $(MODULES_VERSION);\
    else \
      	git -c advice.detachedHead=false clone --branch $(MODULES_VERSION) $(MODULES_SOURCE) $(MODULES_DIR);\
    fi

clean:
	rm -rf $(TF_DATA_DIR) .terraform.lock.hcl .terraform

docs:
	terraform-docs markdown table --output-file parameters.md --output-mode inject $(CURRENT_DIR)
