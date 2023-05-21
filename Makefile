terraform-init-staging:
	cd apps/cloud-iac-terraform && terraform init -upgrade

terraform-plan-staging:
	cd apps/cloud-iac-terraform && terraform plan -var-file=env.tfvars

terraform-apply-staging:
	cd apps/cloud-iac-terraform && terraform apply -var-file=env.tfvars

terraform-apply-staging-auto-approve:
	cd apps/cloud-iac-terraform && terraform apply -var-file=env.tfvars -auto-approve

terraform-plan-staging-out:
	cd apps/cloud-iac-terraform && terraform plan -var-file=env.tfvars -out=tfplan

terraform-destroy-staging:
	cd apps/cloud-iac-terraform && terraform destroy -var-file=env.tfvars
