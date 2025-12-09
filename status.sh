#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║       📊 Kubernetes Cluster Status Dashboard      ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar cluster
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 CLUSTER INFO${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl cluster-info | head -2
echo ""

# Deployments
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 DEPLOYMENTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get deployments 2>/dev/null || echo -e "${RED}No deployments found${NC}"
echo ""

# Pods
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 PODS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PODS=$(kubectl get pods 2>/dev/null)
if [ -n "$PODS" ]; then
    echo "$PODS" | head -1
    echo "$PODS" | tail -n +2 | while read line; do
        STATUS=$(echo $line | awk '{print $3}')
        if [ "$STATUS" == "Running" ]; then
            echo -e "${GREEN}$line${NC}"
        elif [ "$STATUS" == "Pending" ]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${RED}$line${NC}"
        fi
    done
else
    echo -e "${RED}No pods found${NC}"
fi
echo ""

# Services
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 SERVICES${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get services 2>/dev/null || echo -e "${RED}No services found${NC}"
echo ""

# Endpoints Test
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 ENDPOINTS STATUS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test Frontend
if curl -s http://localhost:30000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Frontend:     http://localhost:30000"
else
    echo -e "${RED}✗${NC} Frontend:     http://localhost:30000 (not responding)"
fi

# Test Backend Health
if curl -s http://localhost:30001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend:      http://localhost:30001"
    HEALTH=$(curl -s http://localhost:30001/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo -e "  ${CYAN}└─ Health: $HEALTH${NC}"
else
    echo -e "${RED}✗${NC} Backend:      http://localhost:30001 (not responding)"
fi

# Test Items API
if curl -s http://localhost:30001/api/items > /dev/null 2>&1; then
    ITEM_COUNT=$(curl -s http://localhost:30001/api/items | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo -e "  ${CYAN}└─ Items: $ITEM_COUNT${NC}"
fi

echo ""

# Docker Images
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 DOCKER IMAGES${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
docker images | grep -E "REPOSITORY|backend-api|frontend-web"
echo ""

# Quick Actions
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔹 QUICK ACTIONS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${CYAN}./logs.sh${NC}   - Ver logs de los pods"
echo -e "  ${CYAN}./stop.sh${NC}   - Detener el proyecto"
echo -e "  ${CYAN}./start.sh${NC}  - Iniciar el proyecto"
echo ""