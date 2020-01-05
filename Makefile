init:
	terraform init

plan: init
	terraform plan -var-file=secret.tfvars

apply: init
	terraform apply -var-file=secret.tfvars
