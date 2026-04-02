#!/bin/bash
# =============================================================================
# setup.sh — Configuración inicial del VPS
# Repo: nginx-proxy
# Correr como root en el VPS la primera vez: bash setup.sh
# =============================================================================

set -e

APP_USER="deploy"
PROXY_DIR="/srv/proxy"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

[ "$EUID" -ne 0 ] && err "Este script debe correrse como root"

echo ""
echo "============================================="
echo "  Setup inicial del VPS — nginx-proxy"
echo "============================================="
echo ""

# ── 1. Actualizar sistema ─────────────────────────────────────────────────────
echo "📦 Actualizando paquetes..."
apt update && apt upgrade -y
apt install -y curl git ufw rsync
ok "Sistema actualizado"

# ── 2. Crear usuario no-root ──────────────────────────────────────────────────
echo ""
echo "👤 Creando usuario '$APP_USER'..."
if id "$APP_USER" &>/dev/null; then
  warn "El usuario '$APP_USER' ya existe, saltando..."
else
  adduser --disabled-password --gecos "" "$APP_USER"
  usermod -aG sudo "$APP_USER"
  ok "Usuario '$APP_USER' creado"
fi

# Copiar claves SSH de root al nuevo usuario
mkdir -p /home/$APP_USER/.ssh
cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/ 2>/dev/null \
  || warn "No hay authorized_keys en root — agregala manualmente"
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys 2>/dev/null || true
ok "Claves SSH copiadas a '$APP_USER'"

# ── 3. Instalar Docker ────────────────────────────────────────────────────────
echo ""
echo "🐳 Instalando Docker..."
if command -v docker &>/dev/null; then
  warn "Docker ya instalado ($(docker --version))"
else
  curl -fsSL https://get.docker.com | sh
  ok "Docker instalado"
fi
usermod -aG docker $APP_USER
systemctl enable docker && systemctl start docker
ok "Usuario '$APP_USER' agregado al grupo docker"

# ── 4. Firewall ───────────────────────────────────────────────────────────────
echo ""
echo "🔒 Configurando firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP  — nginx-proxy
ufw allow 443/tcp  # HTTPS — nginx-proxy
# 3306 NO se abre — MySQL solo dentro de Docker
ufw --force enable
ok "Firewall: 22/80/443 abiertos — 3306 cerrado"

# ── 5. Directorios ────────────────────────────────────────────────────────────
echo ""
echo "📁 Creando directorios..."
mkdir -p $PROXY_DIR
chown -R $APP_USER:$APP_USER $PROXY_DIR
ok "Directorio $PROXY_DIR creado"

# ── 6. Red compartida del proxy ── La red se crea con el docker compose ─────────────────────────────────────────────
#echo ""
#echo "🌐 Creando red Docker compartida..."
#if docker network inspect nginx-proxy_net &>/dev/null; then
#  warn "La red 'nginx-proxy_net' ya existe, saltando..."
#else
#  docker network create nginx-proxy_net
#  ok "Red 'nginx-proxy_net' creada"
#fi
# ── 6. Red compartida del proxy ── La red se crea con el docker compose ─────────────────────────────────────────────

# ── 7. Resumen ────────────────────────────────────────────────────────────────
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo 'IP_DEL_VPS')
echo ""
echo "============================================="
ok "Setup del VPS completado"
echo "============================================="
echo ""
echo "Próximos pasos:"
echo "  1. Desde tu máquina local (repo nginx-proxy):"
echo "     ./deploy.sh $VPS_IP"
echo ""
echo "  2. Luego, desde repo aikido-asociacion:"
echo "     ./deploy.sh $VPS_IP"
echo ""
echo "  De ahora en adelante conectate como '$APP_USER':"
echo "     ssh $APP_USER@$VPS_IP"
echo ""
