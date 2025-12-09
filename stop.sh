#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║      🛑 Deteniendo Kubernetes Microservices      ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Selecciona una opción:${NC}"
echo "1) Escalar a 0 réplicas (mantiene configuración, libera recursos)"
echo "2) Eliminar todos los recursos (limpieza completa)"
echo "3) Cancelar"
echo ""
read -p "Opción [1-3]: " option

case $option in
    1)
        echo -e "\n${YELLOW}Escalando deployments a 0 réplicas...${NC}"
        kubectl scale deployment backend --replicas=0
        kubectl scale deployment frontend --replicas=0
        echo -e "${GREEN}✓ Deployments escalados a 0${NC}"
        echo -e "${BLUE}Para reiniciar, ejecuta:${NC}"
        echo "  kubectl scale deployment backend --replicas=3"
        echo "  kubectl scale deployment frontend --replicas=1"
        ;;
    2)
        echo -e "\n${RED}Eliminando todos los recursos...${NC}"
        kubectl delete -f k8s/
        echo -e "${GREEN}✓ Recursos eliminados${NC}"
        echo -e "${BLUE}Para volver a desplegar, ejecuta:${NC}"
        echo "  ./start.sh"
        ;;
    3)
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Estado actual:${NC}"
kubectl get pods