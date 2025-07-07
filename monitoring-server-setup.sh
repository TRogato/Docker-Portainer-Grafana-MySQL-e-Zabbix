#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# =============================================================================
# 🚀✨ Instalador Premium: Zabbix & Monitoring Stack ✨🚀
# 🌐 Portfolio:
#   \e]8;;https://esleylealportfolio.vercel.app/\aVisite meu Portfólio\e]8;;\a
# 🔇 Defina QUIET=false para mostrar logs de instalação
# 🎨 Defina SKIP_DESIGN=true para ocultar banners e emojis
# =============================================================================

# Configurações (silencioso por padrão)
QUIET=${QUIET:-true}
SKIP_DESIGN=${SKIP_DESIGN:-false}

# Wrapper para executar comandos silenciosos
run_cmd() {
  if [ "$QUIET" = "true" ]; then
    "$@" > /dev/null 2>&1
  else
    "$@"
  fi
}

# Cores ANSI
COLOR_RESET="\e[0m"
COLOR_BANNER="\e[1;36m"    # Cyan bold
COLOR_SECTION="\e[1;35m"   # Magenta bold
COLOR_OK="\e[1;32m"        # Green bold
COLOR_WARN="\e[1;33m"      # Yellow bold

# Funções de design
print_banner() {
  if [ "$SKIP_DESIGN" = "false" ]; then
    local emoji="$1" msg="$2"
    echo -e "${COLOR_BANNER}═══════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_BANNER}  ${emoji}  ${msg}  ${emoji}${COLOR_RESET}"
    echo -e "${COLOR_BANNER}═══════════════════════════════════════════════════${COLOR_RESET}"
  fi
}
print_slogan() {
  if [ "$SKIP_DESIGN" = "false" ]; then
    echo -e "${COLOR_SECTION}🔖 Slogan: Conecte, Monitore e Cresça com Elegância!${COLOR_RESET}"
  fi
}

# Banner e slogan iniciais
echo
print_banner "🚀" "Bem-vindo ao Instalador Zabbix & Stack"
print_slogan
[ "$QUIET" = "true" ] || sleep 2

echo
# Etapas de instalação (sempre silenciosas, mostram apenas status)

section() {
  if [ "$SKIP_DESIGN" = "false" ]; then
    echo -e "${COLOR_SECTION}$1${COLOR_RESET}"
  fi
}
finish() {
  echo -e "${COLOR_OK}✔ Concluído!${COLOR_RESET}"
  echo
}

# 1) Preparar ambiente
echo -n "⚙️  Preparando ambiente... "
run_cmd apt-get update -qq && run_cmd apt-get install -y -qq apt-transport-https ca-certificates curl gnupg2 software-properties-common
finish

# 2) Adicionar chave GPG do Docker
echo -n "🔐  Adicionando chave GPG do Docker... "
if [ "$QUIET" = "true" ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - >/dev/null 2>&1
else
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
fi
finish

# 3) Adicionar repositório Docker
echo -n "📦  Adicionando repositório Docker... "
run_cmd add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
run_cmd apt-get update -qq && run_cmd apt-get install -y -qq docker-ce docker-ce-cli containerd.io
finish

# 4) Iniciar Docker
echo -n "🐳  Iniciando Docker... "
run_cmd systemctl start docker && run_cmd systemctl enable docker
finish

# 5) Portainer
echo -n "📑  Iniciando Portainer... "
run_cmd docker run -d --name portainer --restart=always -p 8000:8000 -p 9443:9443 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.9.3
finish

# 6) Grafana
echo -n "📊  Iniciando Grafana... "
run_cmd docker run -d --name grafana --restart=always -p 3000:3000 grafana/grafana-enterprise
finish

# 7) MySQL com healthcheck
echo -n "🗄️  Iniciando MySQL com healthcheck... "
run_cmd docker run -d --name mysql-server --restart=always --health-cmd='mysqladmin ping -h localhost' --health-interval=3s --health-timeout=5s --health-retries=5 -e MYSQL_DATABASE="zabbix" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="zabbix" -e MYSQL_ROOT_PASSWORD="zabbix" mysql:8.0.30 --character-set-server=utf8 --collation-server=utf8_bin --default-authentication-plugin=mysql_native_password

echo -n "⌛  Aguardando MySQL... "
until [ "$(docker inspect -f '{{.State.Health.Status}}' mysql-server)" = "healthy" ]; do echo -n "."; sleep 2; done
echo
finish

# 8) Zabbix Java Gateway
echo -n "☕  Iniciando Zabbix Java Gateway... "
run_cmd docker run -d --name zabbix-java-gateway --restart=unless-stopped zabbix/zabbix-java-gateway
finish

# 9) Zabbix Server
echo -n "🖥️  Iniciando Zabbix Server... "
run_cmd docker run -d --name zabbix-server --restart=unless-stopped -p 10051:10051 --link mysql-server:mysql --link zabbix-java-gateway:zabbix-java-gateway -e DB_SERVER_HOST="mysql-server" -e MYSQL_DATABASE="zabbix" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="zabbix" -e MYSQL_ROOT_PASSWORD="zabbix" zabbix/zabbix-server-mysql
finish

# 10) Zabbix Agent
echo -n "👮  Iniciando Zabbix Agent... "
run_cmd docker run -d --name zabbix-agent --restart=unless-stopped -p 10050:10050 --link zabbix-server:zabbix-server -e ZBX_HOSTNAME="Zabbix server" -e ZBX_SERVER_HOST="zabbix-server" zabbix/zabbix-agent
finish

# 11) Zabbix Web
echo -n "🌐  Iniciando Zabbix Web (NGINX+MySQL)... "
run_cmd docker run -d --name zabbix-web-nginx-mysql --restart=unless-stopped -p 80:8080 --link mysql-server:mysql -e DB_SERVER_HOST="mysql-server" -e MYSQL_DATABASE="zabbix" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="zabbix" -e MYSQL_ROOT_PASSWORD="zabbix" zabbix/zabbix-web-nginx-mysql
finish

# Finalização
echo
print_banner "🎉" "Todos os containers iniciados com sucesso!"
echo -e "${COLOR_OK}Pronto para monitorar! 🚀${COLOR_RESET}"
