#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║         📋 Kubernetes Logs Viewer                ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar que hay pods corriendo
BACKEND_PODS=$(kubectl get pods -l app=backend -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
FRONTEND_PODS=$(kubectl get pods -l app=frontend -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -z "$BACKEND_PODS" ] && [ -z "$FRONTEND_PODS" ]; then
    echo -e "${RED}No hay pods en ejecución${NC}"
    echo "Ejecuta ./start.sh primero"
    exit 1
fi

echo -e "${YELLOW}Pods disponibles:${NC}"
echo ""
echo -e "${GREEN}Backend:${NC}"
i=1
for POD in $BACKEND_PODS; do
    echo "  $i) $POD"
    i=$((i+1))
done

echo ""
echo -e "${GREEN}Frontend:${NC}"
for POD in $FRONTEND_PODS; do
    echo "  $i) $POD"
    i=$((i+1))
done

echo ""
echo "  a) Ver logs de todos los pods backend"
echo "  b) Ver logs de todos los pods frontend"
echo "  c) Ver logs de todos los pods"
echo "  d) Generar reporte completo"
echo ""
read -p "Selecciona una opción: " option

case $option in
    a)
        echo -e "\n${YELLOW}Logs de todos los pods backend:${NC}\n"
        for POD in $BACKEND_PODS; do
            echo -e "${BLUE}=== $POD ===${NC}"
            kubectl logs $POD --tail=50
            echo ""
        done
        ;;
    b)
        echo -e "\n${YELLOW}Logs de todos los pods frontend:${NC}\n"
        for POD in $FRONTEND_PODS; do
            echo -e "${BLUE}=== $POD ===${NC}"
            kubectl logs $POD --tail=50
            echo ""
        done
        ;;
    c)
        echo -e "\n${YELLOW}Logs de todos los pods:${NC}\n"
        for POD in $BACKEND_PODS $FRONTEND_PODS; do
            echo -e "${BLUE}=== $POD ===${NC}"
            kubectl logs $POD --tail=50
            echo ""
        done
        ;;
    d)
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        REPORT_FILE="logs/report_${TIMESTAMP}.log"
        
        echo -e "\n${YELLOW}Generando reporte completo...${NC}"
        
        {
            echo "=========================================="
            echo "KUBERNETES DEPLOYMENT REPORT"
            echo "Generated: $(date)"
            echo "=========================================="
            echo ""
            
            echo "=== CLUSTER INFO ==="
            kubectl cluster-info
            echo ""
            
            echo "=== ALL RESOURCES ==="
            kubectl get all
            echo ""
            
            echo "=== PODS DETAILS ==="
            kubectl get pods -o wide
            echo ""
            
            echo "=== SERVICES ==="
            kubectl get services
            echo ""
            
            echo "=== DEPLOYMENTS ==="
            kubectl get deployments
            echo ""
            
            echo "=== BACKEND DEPLOYMENT DETAILS ==="
            kubectl describe deployment backend
            echo ""
            
            echo "=== FRONTEND DEPLOYMENT DETAILS ==="
            kubectl describe deployment frontend
            echo ""
            
            echo "=== ROLLOUT HISTORY - BACKEND ==="
            kubectl rollout history deployment backend
            echo ""
            
            echo "=== ROLLOUT HISTORY - FRONTEND ==="
            kubectl rollout history deployment frontend
            echo ""
            
            echo "=== POD LOGS ==="
            for POD in $BACKEND_PODS $FRONTEND_PODS; do
                echo ""
                echo "--- Logs: $POD ---"
                kubectl logs $POD
            done
            
            echo ""
            echo "=== API ENDPOINTS TEST ==="
            echo "--- Health Check ---"
            curl -s http://localhost:30001/health 2>/dev/null || echo "Failed to connect"
            echo ""
            echo "--- Items API ---"
            curl -s http://localhost:30001/api/items 2>/dev/null || echo "Failed to connect"
            
        } > $REPORT_FILE
        
        echo -e "${GREEN}✓ Reporte generado: $REPORT_FILE${NC}"
        ;;
    [1-9])
        ALL_PODS=($BACKEND_PODS $FRONTEND_PODS)
        SELECTED_POD=${ALL_PODS[$((option-1))]}
        
        if [ -n "$SELECTED_POD" ]; then
            echo -e "\n${YELLOW}Logs de $SELECTED_POD (siguiendo en tiempo real):${NC}"
            echo -e "${BLUE}Presiona Ctrl+C para salir${NC}\n"
            kubectl logs -f $SELECTED_POD
        else
            echo -e "${RED}Opción inválida${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac