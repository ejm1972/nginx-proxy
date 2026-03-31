# nginx-proxy

Proxy reverso Docker con SSL automático via Let's Encrypt.
Basado en [jwilder/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) + [acme-companion](https://github.com/nginx-proxy/acme-companion).

## Estructura

```
nginx-proxy/
├── docker-compose.proxy.yml   — proxy + acme-companion
├── nginx-custom.conf          — configuración extra de nginx (opcional)
├── setup.sh                   — setup inicial del VPS (correr una vez como root)
└── deploy.sh                  — deploy/actualización del proxy
```

## Primer uso

```bash
# 1. En el VPS como root (una sola vez)
bash setup.sh

# 2. Desde tu máquina local
./deploy.sh IP_DEL_VPS
```

## Agregar una nueva app al proxy

En el `docker-compose` de la app, el servicio web debe tener:

```yaml
environment:
  - VIRTUAL_HOST=miapp.com
  - VIRTUAL_PORT=80
  - LETSENCRYPT_HOST=miapp.com
  - LETSENCRYPT_EMAIL=admin@miapp.com

networks:
  - proxy_net

networks:
  proxy_net:
    external: true
    name: nginx-proxy_net
```

## Comandos útiles

```bash
# Ver estado
docker ps

# Logs del proxy
docker logs proxy_nginx -f

# Logs de SSL
docker logs proxy_acme -f

# Reiniciar proxy
docker compose -f /srv/proxy/docker-compose.proxy.yml restart
```
