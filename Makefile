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
	sudo docker build -t researchers-peers-svc:latest -f apps/researchers/peers/svc/Dockerfile .

researchers-peers-svc-docker-build-no-cache:
#	sudo docker build -t researchers-peers-svc:latest --build-arg SSH_PRIVATE_KEY="$$(cat ~/.ssh/id_rsa)" --no-cache .
	sudo docker build -t researchers-peers-svc:latest -f apps/researchers/peers/svc/Dockerfile --no-cache .

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

terraform-init-staging:
	cd apps/researchers/peers/iac/environments/staging && terraform init -upgrade

terraform-plan-staging:
	cd apps/researchers/peers/iac/environments/staging && terraform plan

terraform-apply-staging:
	cd apps/researchers/peers/iac/environments/staging && terraform apply

terraform-apply-staging-auto-approve:
	cd apps/researchers/peers/iac/environments/staging && terraform apply -auto-approve

terraform-plan-staging-out:
	cd apps/researchers/peers/iac/environments/staging && terraform plan -out=tfplan

terraform-destroy-staging:
	cd apps/researchers/peers/iac/environments/staging && terraform destroy
