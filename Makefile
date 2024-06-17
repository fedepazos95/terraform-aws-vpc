DIRS=${shell find examples -name "*.tf" -exec dirname {} \; | sort --unique}
EXAMPLES=${shell for d in $(DIRS); do basename $$d; done}

all: init-all

init-all:
		@for c in $(EXAMPLES); do \
				$(MAKE) init EXAMPLE=examples/$$c || exit 1; \
		done

plan-all:
		@for c in $(EXAMPLES); do \
				$(MAKE) plan EXAMPLE=examples/$$c || exit 1; \
		done

apply-all:
		@for c in $(EXAMPLES); do \
				$(MAKE) apply EXAMPLE=examples/$$c || exit 1; \
		done

destroy-all:
		@for c in $(EXAMPLES); do \
				$(MAKE) destroy EXAMPLE=examples/$$c || exit 1; \
		done

validate-all:
		@for c in $(EXAMPLES); do \
				$(MAKE) validate EXAMPLE=examples/$$c || exit 1; \
		done

clean-all:
		@for c in $(EXAMPLES); do \
				$(MAKE) clean EXAMPLE=examples/$$c || exit 1; \
		done

plan: init
		cd $(EXAMPLE); terraform plan -var-file fixtures.tfvars

apply: init
		cd $(EXAMPLE); terraform apply -var-file fixtures.tfvars

destroy: init
		cd $(EXAMPLE); terraform destroy -var-file fixtures.tfvars

validate: init
		cd $(EXAMPLE); terraform validate

init:
		rm -rf $(EXAMPLE)/.terraform/*.tfstate
		cd $(EXAMPLE); terraform init;

clean:
		cd $(EXAMPLE); rm -rf .terraform

.PHONY: init-all plan-all apply-all destroy-all validate-all clean-all plan apply destroy validate init clean
