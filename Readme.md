# Monitoring Server Setup

Um conjunto de scripts para automatizar a instalação e configuração de um servidor de monitoramento completo, incluindo Docker, Portainer, Grafana, MySQL e Zabbix.

## 📋 Sumário

- [Descrição](#descrição)
- [Funcionalidades](#funcionalidades)
- [Pré-requisitos](#pré-requisitos)
- [Sistemas Suportados](#sistemas-suportados)
- [Instalação](#instalação)
  

## Descrição

Este repositório contém scripts de shell (`.sh`) que automatizam todo o processo de instalação de um **servidor de monitoramento** em sistemas baseados em Linux (Debian/Ubuntu). São instalados os seguintes componentes em contêineres Docker:

- **Portainer**: interface de gerenciamento de contêineres Docker.
- **Grafana**: painel de visualização de métricas.
- **MySQL**: banco de dados relacional para armazenamento de dados do Zabbix.
- **Zabbix Server & Agent**: plataforma completa de monitoramento de infraestrutura.

## Funcionalidades

- Instalação e configuração do Docker Engine.
- Deploy de Portainer, Grafana, MySQL e Zabbix em contêineres.
- Criação automática de volumes e redes Docker.
- Verificação de versões mais recentes de imagens Docker.
- Logs e status de cada etapa de instalação.

## Pré-requisitos

Antes de começar, certifique-se de ter:

- Acesso root ou permissão `sudo` no servidor.
- Conexão com a internet para baixar pacotes e imagens.
- Firewall configurado (caso necessário), liberando portas:
  - 9000 (Portainer)
  - 3000 (Grafana)
  - 3306 (MySQL)
  - 10051 (Zabbix Server)
  - 10050 (Zabbix Agent)

## Sistemas Suportados

- Ubuntu 20.04+  
- Debian 10+  

## Instalação

1. Clone este repositório:
   ```bash
   git clone https://github.com/TRogato/Docker-Portainer-Grafana-MySQL-e-Zabbix.git
   cd Docker-Portainer-Grafana-MySQL-e-Zabbix
   chmod +x monitoring-NOVO.sh
   ./monitoring-NOVO.sh
   
### Agradecimentos

Este projeto é licenciado sob a Licença MIT.  
Aqui fica o meu agradecimento se você chegou até aqui.

______________________________________________________________________________________________________________________
2. Clone este repositório:
   
Crie um arquivo .env no mesmo diretório com as senhas:

  ```bash
      MYSQL_ZABBIX_PASSWORD=sua_senha_zabbix
      MYSQL_ROOT_PASSWORD=sua_senha_root

## Importante: Substitua sua_senha_zabbix e sua_senha_root "por senhas fortes e seguras".

--- 

**Obrigado por visitar meu repositório!**
