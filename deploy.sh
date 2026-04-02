#!/bin/bash
# =============================================================================
# deploy.sh — Deploy del proxy reverso al VPS
# Repo: nginx-proxy
# Uso: ./deploy.sh [IP_DEL_VPS]
# Requiere haber corrido setup.sh primero
# =============================================================================

set -e

VPS_IP="${1}"
VPS_USER="deploy"
PROXY_DIR="/srv/proxy"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

[ -z "$VPS_IP" ] && err "Falta la IP del VPS. Uso: ./deploy.sh [IP_DEL_VPS]"

echo ""
echo "============================================="
echo "  Deploy proxy reverso → $VPS_IP"
echo "============================================="
echo ""

# ── 1. Copiar archivos ────────────────────────────────────────────────────────
echo "📤 Copiando archivos del proxy..."
scp docker-compose.proxy.yml "$VPS_USER@$VPS_IP:$PROXY_DIR/docker-compose.proxy.yml"
scp .env "$VPS_USER@$VPS_IP:$PROXY_DIR/.env"

# nginx-custom.conf es opcional
if [ -f "nginx-custom.conf" ]; then
  scp nginx-custom.conf "$VPS_USER@$VPS_IP:$PROXY_DIR/nginx-custom.conf"
  ok "nginx-custom.conf copiado"
else
  warn "nginx-custom.conf no encontrado, saltando..."
fi
ok "Archivos del proxy copiados"

# ── 2. Levantar / actualizar proxy ───────────────────────────────────────────
echo "🔀 Levantando proxy reverso..."
ssh "$VPS_USER@$VPS_IP" "
  cd $PROXY_DIR
  docker compose -f docker-compose.proxy.yml up -d --remove-orphans
"
ok "Proxy reverso activo (nginx-proxy + acme-companion)"

# ── 3. Verificar red compartida ── queda creadar dentro del docker compose ─────────────────────────────────────────────
#echo "🌐 Verificando red nginx-proxy_net..."
#ssh "$VPS_USER@$VPS_IP" "
#  if ! docker network inspect nginx-proxy_net &>/dev/null; then
#    docker network create nginx-proxy_net
#    echo 'Red creada'
#  else
#    echo 'Red ya existe'
#  fi
#"
#ok "Red nginx-proxy_net disponible"
# ── 3. Verificar red compartida ── queda creadar dentro del docker compose ─────────────────────────────────────────────

# ── 4. Resumen ────────────────────────────────────────────────────────────────
echo ""
echo "============================================="
ok "Deploy del proxy completado"
echo "============================================="
echo ""
echo "Logs del proxy:       docker logs proxy_nginx -f"
echo "Logs SSL (acme):      docker logs proxy_acme -f"
echo "Estado contenedores:  docker ps"
echo ""
echo "Siguiente paso — deploy de la app aikido:"
echo "  cd ../aikido-asociacion-docker"
echo "  ./deploy.sh $VPS_IP"
echo ""
