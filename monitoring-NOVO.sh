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

# Configurações (silencioso por padrão )
QUIET=${QUIET:-true}
SKIP_DESIGN=${SKIP_DESIGN:-false}

# Cores ANSI
COLOR_RESET="\e[0m"
COLOR_BANNER="\e[1;36m"    # Cyan bold
COLOR_SECTION="\e[1;35m"   # Magenta bold
COLOR_OK="\e[1;32m"        # Green bold
COLOR_WARN="\e[1;33m"      # Yellow bold
COLOR_ERROR="\e[1;31m"     # Red bold

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

section() {
  if [ "$SKIP_DESIGN" = "false" ]; then
    echo -e "${COLOR_SECTION}$1${COLOR_RESET}"
  fi
}
finish() {
  echo -e "${COLOR_OK}✔ Concluído!${COLOR_RESET}"
  echo
}
fail() {
  echo -e "${COLOR_ERROR}❌ Falha! $1${COLOR_RESET}"
  exit 1
}

# Wrapper para executar comandos silenciosos ou verbosos
run_cmd() {
  if [ "$QUIET" = "true" ]; then
    "$@" > /dev/null 2>&1
  else
    "$@"
  fi
}

# Banner e slogan iniciais
echo
print_banner "🚀" "Bem-vindo ao Instalador Zabbix & Stack"
print_slogan
[ "$QUIET" = "true" ] || sleep 2

echo -e "${COLOR_WARN}⚠️  ATENÇÃO: Este script irá instalar Docker e contêineres de monitoramento.${COLOR_RESET}"
echo -e "${COLOR_WARN}   O Zabbix Web será exposto na porta 8080. Se você tem Apache na porta 80,${COLOR_RESET}"
echo -e "${COLOR_WARN}   não haverá conflito direto, mas para acessar o Zabbix na porta 80,${COLOR_RESET}"
echo -e "${COLOR_WARN}   será necessário configurar um proxy reverso (Apache/Nginx) manualmente.${COLOR_RESET}"
echo

# Solicitar senhas para o MySQL
echo -e "${COLOR_SECTION}🔑 Configuração de Senhas do MySQL${COLOR_RESET}"
read -s -p "Digite a senha para o usuário 'zabbix' do MySQL (ex: zabbix): " MYSQL_ZABBIX_PASSWORD
echo
read -s -p "Digite a senha para o usuário 'root' do MySQL (ex: zabbix): " MYSQL_ROOT_PASSWORD
echo
echo

# Etapas de instalação (sempre silenciosas, mostram apenas status)

# 1) Preparar ambiente
echo -n "⚙️  Preparando ambiente... "
run_cmd apt-get update -qq || fail "Falha ao atualizar pacotes."
run_cmd apt-get install -y -qq apt-transport-https ca-certificates curl gnupg2 software-properties-common || fail "Falha ao instalar dependências."
finish

# 2 ) Adicionar chave GPG do Docker
echo -n "🔐  Adicionando chave GPG do Docker... "
if [ "$QUIET" = "true" ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - >/dev/null 2>&1 || fail "Falha ao adicionar chave GPG do Docker."
else
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - || fail "Falha ao adicionar chave GPG do Docker."
fi
finish

# 3 ) Adicionar repositório Docker e instalar Docker CE
echo -n "📦  Adicionando repositório Docker e instalando Docker CE... "
run_cmd add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs ) stable" || fail "Falha ao adicionar repositório Docker."
run_cmd apt-get update -qq || fail "Falha ao atualizar pacotes após adicionar repositório Docker."
run_cmd apt-get install -y -qq docker-ce docker-ce-cli containerd.io || fail "Falha ao instalar Docker CE."
finish

# 4) Iniciar Docker
echo -n "🐳  Iniciando Docker... "
run_cmd systemctl start docker || fail "Falha ao iniciar o serviço Docker."
run_cmd systemctl enable docker || fail "Falha ao habilitar o serviço Docker."
finish

# 5) Portainer
echo -n "📑  Iniciando Portainer... "
run_cmd docker run -d --name portainer --restart=always -p 8000:8000 -p 9443:9443 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.9.3 || fail "Falha ao iniciar Portainer."
finish

# 6) Grafana
echo -n "📊  Iniciando Grafana... "
run_cmd docker run -d --name grafana --restart=always -p 3000:3000 grafana/grafana-enterprise || fail "Falha ao iniciar Grafana."
finish

# 7) MySQL com healthcheck
echo -n "🗄️  Iniciando MySQL com healthcheck... "
run_cmd docker run -d --name mysql-server --restart=always \
  --health-cmd='mysqladmin ping -h localhost' --health-interval=3s --health-timeout=5s --health-retries=5 \
  -e MYSQL_DATABASE="zabbix" \
  -e MYSQL_USER="zabbix" \
  -e MYSQL_PASSWORD="${MYSQL_ZABBIX_PASSWORD}" \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  mysql:8.0.30 --character-set-server=utf8 --collation-server=utf8_bin --default-authentication-plugin=mysql_native_password || fail "Falha ao iniciar MySQL."

echo -n "⌛  Aguardando MySQL ficar saudável... "
for i in $(seq 1 30); do # Tenta por 60 segundos (30 * 2s)
  if [ "$(docker inspect -f '{{.State.Health.Status}}' mysql-server 2>/dev/null)" = "healthy" ]; then
    echo
    break
  fi
  echo -n "."
  sleep 2
  if [ $i -eq 30 ]; then
    fail "MySQL não ficou saudável a tempo. Verifique os logs do contêiner 'mysql-server'."
  fi
done
finish

# 8) Zabbix Java Gateway
echo -n "☕  Iniciando Zabbix Java Gateway... "
run_cmd docker run -d --name zabbix-java-gateway --restart=unless-stopped zabbix/zabbix-java-gateway || fail "Falha ao iniciar Zabbix Java Gateway."
finish

# 9) Zabbix Server
echo -n "🖥️  Iniciando Zabbix Server... "
run_cmd docker run -d --name zabbix-server --restart=unless-stopped -p 10051:10051 \
  --link mysql-server:mysql \
  --link zabbix-java-gateway:zabbix-java-gateway \
  -e DB_SERVER_HOST="mysql-server" \
  -e MYSQL_DATABASE="zabbix" \
  -e MYSQL_USER="zabbix" \
  -e MYSQL_PASSWORD="${MYSQL_ZABBIX_PASSWORD}" \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  zabbix/zabbix-server-mysql || fail "Falha ao iniciar Zabbix Server."
finish

# 10) Zabbix Agent
echo -n "👮  Iniciando Zabbix Agent... "
run_cmd docker run -d --name zabbix-agent --restart=unless-stopped -p 10050:10050 \
  --link zabbix-server:zabbix-server \
  -e ZBX_HOSTNAME="Zabbix server" \
  -e ZBX_SERVER_HOST="zabbix-server" \
  zabbix/zabbix-agent || fail "Falha ao iniciar Zabbix Agent."
finish

# 11) Zabbix Web
echo -n "🌐  Iniciando Zabbix Web (NGINX+MySQL)... "
run_cmd docker run -d --name zabbix-web-nginx-mysql --restart=unless-stopped -p 8080:8080 \
  --link mysql-server:mysql \
  -e DB_SERVER_HOST="mysql-server" \
  -e MYSQL_DATABASE="zabbix" \
  -e MYSQL_USER="zabbix" \
  -e MYSQL_PASSWORD="${MYSQL_ZABBIX_PASSWORD}" \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  zabbix/zabbix-web-nginx-mysql || fail "Falha ao iniciar Zabbix Web."
finish

# Finalização
echo
print_banner "🎉" "Todos os containers iniciados com sucesso!"
echo -e "${COLOR_OK}Pronto para monitorar! 🚀${COLOR_RESET}"
echo
echo -e "${COLOR_SECTION}Informações de Acesso:${COLOR_RESET}"
echo -e "  Portainer: ${COLOR_OK}http://seu_ip:9443${COLOR_RESET}"
echo -e "  Grafana:   ${COLOR_OK}http://seu_ip:3000${COLOR_RESET}"
echo -e "  Zabbix Web: ${COLOR_OK}http://seu_ip:8080${COLOR_RESET}"
echo
echo -e "${COLOR_WARN}Credenciais Iniciais do Zabbix Web:${COLOR_RESET}"
echo -e "  Usuário: ${COLOR_OK}Admin${COLOR_RESET}"
echo -e "  Senha:   ${COLOR_OK}zabbix${COLOR_RESET}"
echo -e "${COLOR_WARN}⚠️  Recomendado alterar a senha do Zabbix imediatamente após o primeiro login!${COLOR_RESET}"
echo
echo -e "${COLOR_WARN}Lembre-se: Para acessar o Zabbix na porta 80, configure um proxy reverso.${COLOR_RESET}"
echo
