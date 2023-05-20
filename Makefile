# Persistence
setup:
	cp .env.example .env \
	&& docker-compose -f docker-compose.yml up -d && echo 'Finish setting up containers...' && sleep 2

cleanup:
	docker-compose -f docker-compose.yml down

prune:
	docker-compose -f docker-compose.yml down -v

# Docker
config:
	docker-compose -f docker-compose.yml config

researchers-peers-svc-docker-build:
#	sudo docker build -t researchers-peers-svc:latest --build-arg SSH_PRIVATE_KEY="$$(cat ~/.ssh/id_rsa)" --no-cache .
	sudo docker build -t researchers-peers-svc:latest -f apps/service-rest-api/Dockerfile .

researchers-peers-svc-docker-build-no-cache:
#	sudo docker build -t researchers-peers-svc:latest --build-arg SSH_PRIVATE_KEY="$$(cat ~/.ssh/id_rsa)" --no-cache .
	sudo docker build -t researchers-peers-svc:latest -f apps/service-rest-api/Dockerfile --no-cache .

researchers-peers-svc-rest-api-docker-run:
	docker run -it --rm -p 8080:8080 researchers-peers-svc:latest bash entrypoints/run-rest-api.sh

researchers-peers-svc-consumer-docker-run:
	docker run -it --rm -p 8080:8080 researchers-peers-svc:latest bash entrypoints/run-consumer.sh

# Application
researchers-peers-svc-prisma-postgresql-setup:
	yarn prisma generate --schema libs/researchers/peers/adapters/src/database/infra/prisma/postgresql.schema.prisma

researchers-peers-svc-rest-api-serve:
	# The .env in root folder make it possible to use env variables within .env file
	cp .env.example apps/researchers/peers/svc-rest-api/.env && make researchers-peers-svc-prisma-postgresql-setup && yarn nx serve researchers-peers-svc-rest-api

researchers-peers-svc-consumer-with-api-serve:
	# The .env in root folder make it possible to use env variables within .env file
	cp .env.example .env && make auth-prisma-postgresql-setup && nx serve consumer-with-api

researchers-peers-svc-consumer-serve:
	# The .env in root folder make it possible to use env variables within .env file
	cp .env.example .env && make auth-prisma-postgresql-setup && nx serve service-consumer

# Fly
fly-launch:
	cd apps/service-rest-api && fly launch

fly-deploy:
	cd apps/service-rest-api && fly deploy

fly-logs:
	cd apps/service-rest-api && fly logs

fly-status:
	cd apps/service-rest-api && fly status

fly-status-watch:
	cd apps/service-rest-api && fly status --watch

fly-open:
	cd apps/service-rest-api && fly open

fly-volume-create-data:
	cd apps/service-rest-api && fly vol create data --region gru --size 1

fly-volumes-list:
	cd apps/service-rest-api && fly volumes list

fly-apps-list:
	cd apps/service-rest-api && fly apps list

fly-apps-destroy:
	cd apps/service-rest-api && fly apps destroy black-fog-4181

fly-mount-volume:
	cd apps/service-rest-api && fly m run . -v vol_xme149kwxy3vowpl:/data

fly-secrets-set:
	cd apps/service-rest-api && fly secrets set

fly-secrets-list:
	fly secrets list

terraform-init-staging:
	cd apps/service-iac/environments/staging && terraform init

terraform-plan-staging:
	cd apps/service-iac/environments/staging && terraform plan

terraform-apply-staging:
	cd apps/service-iac/environments/staging && terraform apply

terraform-apply-staging-auto-approve:
	cd apps/service-iac/environments/staging && terraform apply -auto-approve

terraform-plan-staging-out:
	cd apps/service-iac/environments/staging && terraform plan -out=tfplan

terraform-destroy-staging:
	cd apps/service-iac/environments/staging && terraform destroy
