.PHONY: help up down restart status logs clean build rebuild

# Colores para output
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
NC     := \033[0m

help: ## Mostrar esta ayuda
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Kubernetes Microservices - Comandos Disponibles  $(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

up: ## Iniciar todo el proyecto (build + deploy)
	@echo "$(GREEN)🚀 Iniciando proyecto...$(NC)"
	@./start.sh

down: ## Detener el proyecto (escala a 0)
	@echo "$(YELLOW)⏸️  Deteniendo proyecto...$(NC)"
	@kubectl scale deployment backend --replicas=0
	@kubectl scale deployment frontend --replicas=0
	@echo "$(GREEN)✓ Proyecto detenido$(NC)"

clean: ## Eliminar todos los recursos
	@echo "$(YELLOW)🗑️  Limpiando recursos...$(NC)"
	@kubectl delete -f k8s/ 2>/dev/null || true
	@echo "$(GREEN)✓ Recursos eliminados$(NC)"

restart: down up ## Reiniciar el proyecto

status: ## Ver estado del cluster
	@./status.sh

logs: ## Ver logs de los pods
	@./logs.sh

build: ## Construir imágenes Docker
	@echo "$(GREEN)🔨 Construyendo imágenes...$(NC)"
	@docker build -t backend-api:v1 ./backend
	@docker build -t frontend-web:v1 ./frontend
	@echo "$(GREEN)✓ Imágenes construidas$(NC)"

rebuild: clean build up ## Reconstruir todo desde cero

scale-up: ## Escalar backend a 5 réplicas
	@echo "$(GREEN)⬆️  Escalando backend a 5 réplicas...$(NC)"
	@kubectl scale deployment backend --replicas=5
	@sleep 3
	@kubectl get pods

scale-down: ## Escalar backend a 2 réplicas
	@echo "$(YELLOW)⬇️  Escalando backend a 2 réplicas...$(NC)"
	@kubectl scale deployment backend --replicas=2
	@sleep 3
	@kubectl get pods

test: ## Probar endpoints de la API
	@echo "$(BLUE)Testing endpoints...$(NC)"
	@echo ""
	@echo "$(YELLOW)Health Check:$(NC)"
	@curl -s http://localhost:30001/health | jq 2>/dev/null || curl -s http://localhost:30001/health
	@echo ""
	@echo ""
	@echo "$(YELLOW)Items API:$(NC)"
	@curl -s http://localhost:30001/api/items | jq 2>/dev/null || curl -s http://localhost:30001/api/items
	@echo ""

open: ## Abrir frontend en el navegador
	@echo "$(GREEN)🌐 Abriendo frontend...$(NC)"
	@open http://localhost:30000 2>/dev/null || xdg-open http://localhost:30000 2>/dev/null || start http://localhost:30000

dashboard: ## Abrir Kubernetes Dashboard (si está instalado)
	@kubectl proxy &
	@open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ 2>/dev/null || echo "Dashboard no instalado"

pod-shell: ## Abrir shell en un pod del backend
	@POD=$$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}'); \
	echo "$(GREEN)Conectando a pod: $$POD$(NC)"; \
	kubectl exec -it $$POD -- /bin/sh

watch: ## Ver estado en tiempo real
	@watch -n 2 kubectl get pods

images: ## Listar imágenes Docker del proyecto
	@docker images | grep -E "REPOSITORY|backend-api|frontend-web"

prune: ## Limpiar recursos no usados
	@echo "$(YELLOW)🧹 Limpiando recursos de Docker...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✓ Limpieza completada$(NC)"