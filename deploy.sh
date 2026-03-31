#!/bin/bash
# =============================================================================
# deploy.sh — Deploy de nginx-proxy a VPS
# Uso: ./deploy.sh [IP_DEL_VPS]
# Ejemplo: ./deploy.sh 123.456.789.0
# =============================================================================

set -e  # detener si cualquier comando falla

# ── Configuración ─────────────────────────────────────────────────────────────
DOMINIO="ada.coninf.com.ar"
VPS_IP="${1}"                        # se pasa como argumento
VPS_USER="deploy"                    # usuario creado por setup.sh
REMOTE_DIR="/opt/apps/nginx-proxy"
APP_DIR="."       # ruta local al código PHP

# ── Validaciones ──────────────────────────────────────────────────────────────
if [ -z "$VPS_IP" ]; then
  echo "❌ Falta la IP del VPS. Uso: ./deploy.sh [IP_DEL_VPS]"
  exit 1
fi

if [ ! -f ".env" ]; then
  echo "❌ No existe el archivo .env. Copiá .env.example y completalo."
  exit 1
fi

echo "🚀 Iniciando deploy en $VPS_IP..."

# ── 1. Instalar Docker en el VPS (solo la primera vez) ────────────────────────
echo "📦 Verificando Docker en el VPS..."
ssh "$VPS_USER@$VPS_IP" '
  if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    apt update && apt install -y docker.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker instalado"
  else
    echo "✅ Docker ya está instalado"
  fi
'

# ── 2. Crear estructura de directorios en el VPS ──────────────────────────────
echo "📁 Creando directorios en el VPS..."
ssh "$VPS_USER@$VPS_IP" "mkdir -p $REMOTE_DIR"

# ── 3. Copiar archivos de configuración ───────────────────────────────────────
echo "📤 Copiando archivos de configuración..."
scp docker-compose.yml "$VPS_USER@$VPS_IP:$REMOTE_DIR/docker-compose.yml"
scp nginx-custom.conf        "$VPS_USER@$VPS_IP:$REMOTE_DIR/nginx-custom.conf"

# ── 5. Levantar contenedores ──────────────────────────────────────────────────
echo "🐳 Levantando contenedores (solo HTTP por ahora)..."
ssh "$VPS_USER@$VPS_IP" "
  cd $REMOTE_DIR
  docker compose up -d
"

# ── 6. Obtener certificado SSL (solo si no existe) ────────────────────────────
echo "🔒 Verificando certificado SSL..."
ssh "$VPS_USER@$VPS_IP" "
  if [ ! -f /etc/letsencrypt/live/$DOMINIO/fullchain.pem ]; then
    echo 'Obteniendo certificado Let'\''s Encrypt...'
    docker compose -f $REMOTE_DIR/docker-compose.yml run --rm certbot certonly \
      --webroot \
      --webroot-path=/var/www/certbot \
      --email admin@$DOMINIO \
      --agree-tos \
      --no-eff-email \
      -d $DOMINIO \
      -d www.$DOMINIO

    echo 'Restaurando configuración HTTPS en nginx...'
    sed -i 's/^#TEMP# //' $REMOTE_DIR/nginx.prod.conf
    docker compose -f $REMOTE_DIR/docker-compose.yml exec nginx nginx -s reload
    echo '✅ SSL configurado correctamente'
  else
    echo '✅ Certificado ya existe, saltando...'
    # En redeploys, solo recargar nginx
    docker compose -f $REMOTE_DIR/docker-compose.yml exec nginx nginx -s reload
  fi
"

# ── 7. Verificación final ─────────────────────────────────────────────────────
echo ""
echo "✅ Deploy completado"
echo "🌐 Tu app está en: https://$DOMINIO"
echo ""
echo "Comandos útiles en el VPS:"
echo "  Ver logs:       docker compose logs -f"
echo "  Ver estado:     docker compose ps"
echo "  Reiniciar:      docker compose restart"
echo "  Apagar:         docker compose down"
