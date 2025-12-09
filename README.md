# 🚀 Kubernetes Microservices Project

Proyecto de demostración de orquestación de microservicios usando Kubernetes, Docker y kubectl.

## 📋 Tabla de Contenidos

- [Prerequisitos](#prerequisitos)
- [Inicio Rápido](#inicio-rápido)
- [Uso de Scripts](#uso-de-scripts)
- [Uso con Makefile](#uso-con-makefile)
- [Arquitectura](#arquitectura)
- [Comandos Manuales](#comandos-manuales)
- [Troubleshooting](#troubleshooting)

---

## 📦 Prerequisitos

Antes de comenzar, asegúrate de tener instalado:

- **Docker Desktop** (con Kubernetes habilitado)
  - [Descargar Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Habilitar Kubernetes: Settings → Kubernetes → Enable Kubernetes
- **kubectl** (viene con Docker Desktop)
- **curl** (para probar endpoints)
- **make** (opcional, para usar Makefile)

### Verificar instalación:

```bash
docker --version
kubectl version --client
kubectl cluster-info
```

---

## ⚡ Inicio Rápido

### Opción 1: Script Automatizado (RECOMENDADO)

```bash
# 1. Dar permisos de ejecución a los scripts
chmod +x *.sh

# 2. Iniciar todo el proyecto
./start.sh

# Espera ~30 segundos y todo estará listo
```

### Opción 2: Usando Makefile (estilo docker-compose)

```bash
# Ver comandos disponibles
make help

# Iniciar proyecto
make up

# Ver estado
make status

# Abrir frontend
make open
```

---

## 🎯 Uso de Scripts

### `start.sh` - Iniciar Proyecto

Automatiza todo el proceso:
- ✅ Verifica prerequisitos
- ✅ Construye imágenes Docker
- ✅ Despliega en Kubernetes
- ✅ Escala automáticamente
- ✅ Genera logs completos
- ✅ Verifica endpoints

```bash
./start.sh
```

**Salida:**
- Logs en tiempo real en la terminal
- Log completo guardado en `logs/deployment_YYYYMMDD_HHMMSS.log`
- URLs de acceso al finalizar

---

### `stop.sh` - Detener Proyecto

Dos opciones para detener:

```bash
./stop.sh
```

**Opciones:**
1. Escalar a 0 réplicas (mantiene configuración)
2. Eliminar todos los recursos (limpieza completa)

---

### `logs.sh` - Ver Logs

Ver logs de pods de forma interactiva:

```bash
./logs.sh
```

**Opciones:**
- Ver logs de pods individuales
- Ver logs de todos los backend
- Ver logs de todos los frontend
- Generar reporte completo
- Seguir logs en tiempo real (`-f`)

---

### `status.sh` - Ver Estado

Dashboard del estado actual del cluster:

```bash
./status.sh
```

**Muestra:**
- 📊 Info del cluster
- 🚀 Deployments activos
- 📦 Pods y su estado
- 🌐 Services disponibles
- ✓ Status de endpoints (con health checks)
- 🐳 Imágenes Docker

---

## 🛠️ Uso con Makefile

El Makefile proporciona comandos simples tipo docker-compose:

### Comandos Principales

```bash
make up          # Iniciar todo
make down        # Detener (escala a 0)
make restart     # Reiniciar
make status      # Ver estado
make logs        # Ver logs
make clean       # Eliminar recursos
make build       # Construir imágenes
make rebuild     # Reconstruir todo
```

### Comandos de Escalado

```bash
make scale-up    # Escalar backend a 5 réplicas
make scale-down  # Escalar backend a 2 réplicas
```

### Comandos de Testing

```bash
make test        # Probar endpoints
make open        # Abrir frontend en navegador
make watch       # Ver pods en tiempo real
```

### Comandos de Mantenimiento

```bash
make images      # Ver imágenes del proyecto
make prune       # Limpiar recursos Docker
make pod-shell   # Abrir shell en un pod
```

---

## 🏗️ Arquitectura

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │ :30000
       ▼
┌─────────────┐     :30001      ┌─────────────┐
│  Frontend   │ ───────────────► │   Backend   │
│  (Nginx)    │                  │  (Node.js)  │
│  1 réplica  │                  │  3 réplicas │
└─────────────┘                  └─────────────┘
```

### Componentes

- **Frontend**: Nginx sirviendo HTML/JS estático
- **Backend**: API REST en Node.js/Express
- **Services**: NodePort para acceso local
- **Deployments**: Gestión declarativa de pods

---

## 📝 Comandos Manuales

Si prefieres ejecutar comandos manualmente:

### Construcción

```bash
docker build -t backend-api:v1 ./backend
docker build -t frontend-web:v1 ./frontend
```

### Despliegue

```bash
kubectl apply -f k8s/
kubectl get all
kubectl get pods
```

### Escalado

```bash
kubectl scale deployment backend --replicas=3
kubectl get pods
```

### Logs

```bash
# Logs de un pod específico
kubectl logs <pod-name>

# Seguir logs en tiempo real
kubectl logs -f <pod-name>

# Logs de todos los pods backend
kubectl logs -l app=backend
```

### Inspección

```bash
kubectl describe deployment backend
kubectl describe pod <pod-name>
kubectl get services
kubectl rollout history deployment backend
```

### Endpoints

```bash
curl http://localhost:30001/health
curl http://localhost:30001/api/items
```

### Limpieza

```bash
# Escalar a 0
kubectl scale deployment backend --replicas=0
kubectl scale deployment frontend --replicas=0

# Eliminar recursos
kubectl delete -f k8s/

# Eliminar imágenes
docker rmi backend-api:v1 frontend-web:v1
```

---

## 🌐 Acceso a la Aplicación

Una vez desplegado:

- **Frontend**: http://localhost:30000
- **Backend API**: http://localhost:30001
- **Health Check**: http://localhost:30001/health
- **Items API**: http://localhost:30001/api/items

---

## 📊 Estructura del Proyecto

```
kubernetes-microservices/
├── backend/
│   ├── server.js           # API REST
│   ├── package.json        # Dependencias
│   └── Dockerfile          # Imagen Docker
├── frontend/
│   ├── index.html          # Interfaz web
│   └── Dockerfile          # Imagen Docker
├── k8s/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
├── logs/                   # Logs generados
├── start.sh               # Script de inicio
├── stop.sh                # Script de parada
├── logs.sh                # Script de logs
├── status.sh              # Script de estado
├── Makefile               # Comandos make
└── README.md              # Este archivo
```

---

## 🔧 Troubleshooting

### Los pods no inician

```bash
# Ver detalles del pod
kubectl describe pod <pod-name>

# Ver logs de error
kubectl logs <pod-name>

# Verificar imágenes
docker images | grep -E "backend|frontend"
```

### Endpoints no responden

```bash
# Verificar services
kubectl get services

# Verificar que los pods están Running
kubectl get pods

# Verificar health checks
kubectl describe deployment backend | grep -A 10 "Liveness"
```

### Docker Desktop no responde

1. Reiniciar Docker Desktop
2. Verificar que Kubernetes esté habilitado
3. Ejecutar `kubectl cluster-info`

### Limpiar y empezar de nuevo

```bash
make clean        # o ./stop.sh (opción 2)
make rebuild      # o ./start.sh
```

---

## 📚 Recursos Adicionales

- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Documentación de Docker](https://docs.docker.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## 🤝 Contribuciones

Este es un proyecto educativo. Para mejoras:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -am 'Agregar mejora'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Crea un Pull Request

---

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

## 👤 Autor

[Tu Nombre] - Proyecto Final de Contenedores y Orquestación

---

**¡Disfruta tu demo de Kubernetes! 🚀**