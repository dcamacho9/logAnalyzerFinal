#!/bin/bash
# ==============================================
# Docker Quick Start Script - Linux/macOS
# ==============================================

set -e  # Exit on error

COLORS_ENABLED=true
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        echo "Descárgalo desde: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    print_success "Docker encontrado: $(docker --version)"
}

# Check if docker-compose is installed
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose no está instalado"
        exit 1
    fi
    print_success "docker-compose encontrado: $(docker-compose --version)"
}

# Create .env from example
setup_env() {
    if [ ! -f ".env" ]; then
        print_warning ".env no encontrado"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Creado .env desde .env.example"
            print_info "Edita .env con tus valores específicos"
        else
            print_error ".env.example no encontrado"
            exit 1
        fi
    else
        print_success ".env ya existe"
    fi
}

# Build images
build() {
    print_header "Building Docker Images"
    docker-compose build "$@"
    print_success "Build completado"
}

# Start services
start() {
    print_header "Iniciando Servicios"
    setup_env
    
    docker-compose up -d "$@"
    print_success "Servicios iniciados"
    
    sleep 5
    status
}

# Stop services
stop() {
    print_header "Deteniendo Servicios"
    docker-compose stop "$@"
    print_success "Servicios detenidos"
}

# Down and remove
down() {
    print_header "Deteniendo y Removiendo Contenedores"
    docker-compose down "$@"
    print_success "Contenedores removidos"
}

# Show status
status() {
    print_header "Estado de Servicios"
    docker-compose ps
    
    print_info "\nVerificando health endpoints..."
    
    if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
        print_success "API: http://localhost:5000/api/health"
    else
        print_warning "API: No responde aún (puede estar iniciando)"
    fi
    
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "OLLAMA: http://localhost:11434/api/tags"
    else
        print_warning "OLLAMA: No responde aún"
    fi
}

# Show logs
logs() {
    print_header "Logs"
    docker-compose logs -f "$@"
}

# Execute shell in container
shell() {
    local container="${1:-log-analyzer-agent}"
    print_info "Entrando en shell del contenedor: $container"
    docker-compose exec "$container" /bin/bash
}

# Test API
test_api() {
    print_header "Testing API"
    
    print_info "1. Probando /api/health..."
    curl -s http://localhost:5000/api/health | jq '.' || echo "Error en health check"
    
    print_info "\n2. Probando /api/analyze..."
    curl -s -X POST http://localhost:5000/api/analyze \
        -H "Content-Type: application/json" \
        -d '{"logs":"[ERROR] Test error message"}' | jq '.' || echo "Error en analyze"
}

# Clean everything
clean() {
    print_header "LIMPIEZA COMPLETA"
    print_warning "Esto borrará contenedores y volúmenes"
    
    read -p "¿Continuar? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        docker-compose down -v
        print_success "Limpieza completada"
    else
        print_info "Operación cancelada"
    fi
}

# Show help
show_help() {
    cat << EOF
${BLUE}Log Analyzer Docker Manager${NC}

Uso: $0 [COMANDO] [OPCIONES]

Comandos:
  start [SERVICIO]      Iniciar servicios (default: todos)
  stop [SERVICIO]       Detener servicios
  down [OPCIONES]       Detener y remover contenedores
  build [SERVICIO]      Compilar imágenes
  status                Ver estado de servicios
  logs [SERVICIO]       Ver logs en tiempo real
  shell [CONTENEDOR]    Entrar en shell del contenedor
  test                  Probar endpoints del API
  clean                 Limpiar contenedores y volúmenes (⚠️)
  help                  Mostrar esta ayuda

Ejemplos:
  $0 start                          # Iniciar todo
  $0 start log-analyzer-agent       # Iniciar solo el agente
  $0 logs log-analyzer-agent        # Ver logs del agente
  $0 shell log-analyzer-agent       # Shell interactivo
  $0 stop                           # Detener todo
  $0 down -v                        # Remover todo incluyendo volúmenes
  $0 clean                          # Limpieza completa con confirmación

Servicios disponibles:
  - ollama
  - log-analyzer-agent

EOF
}

# Main
main() {
    case "${1:-start}" in
        start)
            check_docker
            check_docker_compose
            start "${@:2}"
            ;;
        stop)
            check_docker
            check_docker_compose
            stop "${@:2}"
            ;;
        down)
            check_docker
            check_docker_compose
            down "${@:2}"
            ;;
        build)
            check_docker
            check_docker_compose
            build "${@:2}"
            ;;
        status)
            check_docker
            check_docker_compose
            status
            ;;
        logs)
            check_docker
            check_docker_compose
            logs "${@:2}"
            ;;
        shell)
            check_docker
            check_docker_compose
            shell "${2:-log-analyzer-agent}"
            ;;
        test)
            test_api
            ;;
        clean)
            check_docker
            check_docker_compose
            clean
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            print_error "Comando desconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
