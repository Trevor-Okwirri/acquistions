# Makefile for Dockerized Acquisitions App

.PHONY: help dev-up dev-down dev-logs dev-build prod-up prod-down prod-logs dev-migrate dev-generate dev-studio clean

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development commands
dev-setup: ## Copy development environment template
	@if [ ! -f .env.development ]; then \
		cp .env.development.example .env.development; \
		echo "Created .env.development - please update with your credentials"; \
	else \
		echo ".env.development already exists"; \
	fi

dev-up: ## Start development environment with Neon Local
	docker compose -f docker-compose.dev.yml up --build

dev-up-d: ## Start development environment in background
	docker compose -f docker-compose.dev.yml up --build -d

dev-down: ## Stop development environment
	docker compose -f docker-compose.dev.yml down

dev-logs: ## Show development logs
	docker compose -f docker-compose.dev.yml logs -f

dev-build: ## Build development image
	docker compose -f docker-compose.dev.yml build

dev-restart: ## Restart development environment
	docker compose -f docker-compose.dev.yml restart

# Database operations
dev-migrate: ## Run database migrations in development
	docker compose -f docker-compose.dev.yml exec app npm run db:migrate

dev-generate: ## Generate database migrations in development  
	docker compose -f docker-compose.dev.yml exec app npm run db:generate

dev-studio: ## Open Drizzle Studio in development
	docker compose -f docker-compose.dev.yml exec app npm run db:studio

# Production commands
prod-up: ## Start production environment
	docker compose -f docker-compose.prod.yml up --build -d

prod-down: ## Stop production environment
	docker compose -f docker-compose.prod.yml down

prod-logs: ## Show production logs
	docker compose -f docker-compose.prod.yml logs -f

prod-build: ## Build production image
	docker compose -f docker-compose.prod.yml build

prod-ps: ## Show production container status
	docker compose -f docker-compose.prod.yml ps

# Utility commands
shell: ## Access development container shell
	docker compose -f docker-compose.dev.yml exec app sh

test-connection: ## Test database connection in development
	docker compose -f docker-compose.dev.yml exec app node -e "import { sql } from './src/config/database.js'; sql\`SELECT 1\`.then(() => console.log('✅ Connected')).catch(console.error);"

clean: ## Clean up Docker resources
	docker compose -f docker-compose.dev.yml down -v
	docker compose -f docker-compose.prod.yml down -v
	docker system prune -f

clean-all: ## Clean up everything including images
	docker compose -f docker-compose.dev.yml down -v --rmi all
	docker compose -f docker-compose.prod.yml down -v --rmi all
	docker system prune -a -f