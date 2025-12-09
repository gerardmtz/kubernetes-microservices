#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Crear directorio de logs
LOGS_DIR="logs"
mkdir -p $LOGS_DIR
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/deployment_${TIMESTAMP}.log"

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a $LOG_FILE
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

separator() {
    echo -e "\n${YELLOW}========================================${NC}" | tee -a $LOG_FILE
    echo -e "${YELLOW}$1${NC}" | tee -a $LOG_FILE
    echo -e "${YELLOW}========================================${NC}\n" | tee -a $LOG_FILE
}

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║   🚀 Kubernetes Microservices Deployment Tool    ║
║          Automated Setup & Deployment            ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log "Iniciando despliegue automatizado del proyecto..."
log "Log file: $LOG_FILE"

# 1. Verificar prerequisitos
separator "PASO 1: Verificando Prerequisites"

info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado. Por favor instala Docker Desktop."
    exit 1
fi
log "✓ Docker encontrado: $(docker --version)"

info "Verificando kubectl..."
if ! command -v kubectl &> /dev/null; then
    error "kubectl no está instalado."
    exit 1
fi
log "✓ kubectl encontrado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

info "Verificando cluster de Kubernetes..."
if ! kubectl cluster-info &> /dev/null; then
    error "Kubernetes no está corriendo. Por favor inicia Docker Desktop y habilita Kubernetes."
    exit 1
fi
log "✓ Cluster de Kubernetes activo"

# 2. Construir imágenes Docker
separator "PASO 2: Construyendo Imágenes Docker"

info "Verificando si las imágenes ya existen..."
BACKEND_EXISTS=$(docker images -q backend-api:v1)
FRONTEND_EXISTS=$(docker images -q frontend-web:v1)

if [ -z "$BACKEND_EXISTS" ]; then
    log "Construyendo imagen del backend..."
    docker build -t backend-api:v1 ./backend >> $LOG_FILE 2>&1
    if [ $? -eq 0 ]; then
        log "✓ Imagen backend-api:v1 construida exitosamente"
    else
        error "Falló la construcción de la imagen del backend"
        exit 1
    fi
else
    warning "Imagen backend-api:v1 ya existe. Omitiendo construcción."
fi

if [ -z "$FRONTEND_EXISTS" ]; then
    log "Construyendo imagen del frontend..."
    docker build -t frontend-web:v1 ./frontend >> $LOG_FILE 2>&1
    if [ $? -eq 0 ]; then
        log "✓ Imagen frontend-web:v1 construida exitosamente"
    else
        error "Falló la construcción de la imagen del frontend"
        exit 1
    fi
else
    warning "Imagen frontend-web:v1 ya existe. Omitiendo construcción."
fi

# 3. Limpiar despliegues anteriores (si existen)
separator "PASO 3: Limpiando Recursos Existentes"

if kubectl get deployment backend &> /dev/null; then
    warning "Encontrados recursos existentes. Limpiando..."
    kubectl delete -f k8s/ >> $LOG_FILE 2>&1
    sleep 5
    log "✓ Recursos anteriores eliminados"
else
    info "No se encontraron recursos existentes"
fi

# 4. Desplegar en Kubernetes
separator "PASO 4: Desplegando en Kubernetes"

log "Aplicando manifiestos de Kubernetes..."
kubectl apply -f k8s/ | tee -a $LOG_FILE

log "Esperando a que los pods estén listos..."
sleep 10

# Verificar que los pods estén corriendo
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    BACKEND_READY=$(kubectl get pods -l app=backend -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null)
    FRONTEND_READY=$(kubectl get pods -l app=frontend -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null)
    
    if [[ "$BACKEND_READY" == *"true"* ]] && [[ "$FRONTEND_READY" == *"true"* ]]; then
        log "✓ Todos los pods están listos"
        break
    fi
    
    info "Esperando a que los pods estén listos... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    error "Timeout: Los pods no estuvieron listos a tiempo"
    kubectl get pods | tee -a $LOG_FILE
    exit 1
fi

# 5. Recolectar información del despliegue
separator "PASO 5: Recolectando Información del Despliegue"

echo "=== kubectl get all ===" >> $LOG_FILE
kubectl get all | tee -a $LOG_FILE

echo -e "\n=== kubectl get pods ===" >> $LOG_FILE
kubectl get pods | tee -a $LOG_FILE

echo -e "\n=== kubectl get services ===" >> $LOG_FILE
kubectl get services | tee -a $LOG_FILE

echo -e "\n=== kubectl get deployments ===" >> $LOG_FILE
kubectl get deployments | tee -a $LOG_FILE

echo -e "\n=== kubectl describe deployment backend ===" >> $LOG_FILE
kubectl describe deployment backend >> $LOG_FILE

# 6. Escalar backend a 3 réplicas
separator "PASO 6: Escalando Backend a 3 Réplicas"

log "Escalando backend deployment..."
kubectl scale deployment backend --replicas=3 | tee -a $LOG_FILE
sleep 5

echo -e "\n=== kubectl get pods (después del escalado) ===" >> $LOG_FILE
kubectl get pods | tee -a $LOG_FILE

# 7. Obtener logs de los pods
separator "PASO 7: Recolectando Logs de Pods"

BACKEND_PODS=$(kubectl get pods -l app=backend -o jsonpath='{.items[*].metadata.name}')
for POD in $BACKEND_PODS; do
    echo -e "\n=== Logs del pod: $POD ===" >> $LOG_FILE
    kubectl logs $POD >> $LOG_FILE 2>&1
done

echo -e "\n=== kubectl rollout history deployment backend ===" >> $LOG_FILE
kubectl rollout history deployment backend >> $LOG_FILE

# 8. Verificar endpoints
separator "PASO 8: Verificando Endpoints"

log "Esperando a que los servicios estén disponibles..."
sleep 5

info "Probando health endpoint..."
if curl -s http://localhost:30001/health > /dev/null; then
    echo -e "\n=== Health Check Response ===" >> $LOG_FILE
    curl -s http://localhost:30001/health | tee -a $LOG_FILE
    echo "" >> $LOG_FILE
    log "✓ Backend health check: OK"
else
    error "Backend health check falló"
fi

info "Probando items endpoint..."
if curl -s http://localhost:30001/api/items > /dev/null; then
    echo -e "\n=== Items API Response ===" >> $LOG_FILE
    curl -s http://localhost:30001/api/items | tee -a $LOG_FILE
    echo "" >> $LOG_FILE
    log "✓ Backend items API: OK"
else
    error "Backend items API falló"
fi

# 9. Resumen final
separator "DESPLIEGUE COMPLETADO"

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║            ✅ DESPLIEGUE EXITOSO ✅               ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log "Resumen del despliegue:"
echo ""
info "📦 Imágenes Docker:"
echo "   - backend-api:v1"
echo "   - frontend-web:v1"
echo ""
info "🚀 Recursos Kubernetes desplegados:"
kubectl get deployments | tail -n +2 | awk '{print "   - " $1 " (" $2 " réplicas)"}'
echo ""
info "🌐 Servicios disponibles:"
echo "   - Frontend: http://localhost:30000"
echo "   - Backend API: http://localhost:30001"
echo "   - Health Check: http://localhost:30001/health"
echo "   - Items API: http://localhost:30001/api/items"
echo ""
info "📊 Pods en ejecución:"
kubectl get pods | tail -n +2 | awk '{print "   - " $1 " (" $3 ")"}'
echo ""
info "📝 Log completo guardado en: $LOG_FILE"
echo ""

log "Para ver los logs en tiempo real:"
echo "   tail -f $LOG_FILE"
echo ""
log "Para detener el proyecto:"
echo "   ./stop.sh"
echo ""
log "Para ver los logs de los pods:"
echo "   ./logs.sh"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}¡Tu aplicación está lista para la demo!${NC}"
echo -e "${BLUE}========================================${NC}"
