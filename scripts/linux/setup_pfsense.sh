#!/bin/bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo "=========================================="
echo "Configuración Automatizada pfSense NORCOM"
echo "=========================================="

# Detectar si estamos en el repo root
if [ ! -d "inventory" ] || [ ! -d "playbooks" ]; then
    echo -e "${RED}Error: Ejecutar desde la raiz del proyecto ansible_DC/${NC}"
    echo "  cd /ruta/a/ansible_DC && bash scripts/linux/setup_pfsense.sh"
    exit 1
fi

INVENTORY="inventory/production/hosts.ini"

# Paso 1: Instalar colecciones
echo -e "${YELLOW}[1/4] Instalando colecciones Ansible...${NC}"
ansible-galaxy collection install -r playbooks/routers/requirements.yml --force
echo -e "${GREEN}✓ Colecciones instaladas${NC}"

# Paso 2: Verificar conectividad
echo -e "${YELLOW}[2/4] Verificando conectividad a pfSense...${NC}"

ping -c 2 172.17.25.64 > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ Master (172.17.25.64) alcanzable${NC}" || \
  echo -e "${RED}✗ Master (172.17.25.64) NO alcanzable${NC}"

ping -c 2 172.17.25.65 > /dev/null 2>&1 && \
  echo -e "${GREEN}✓ Backup (172.17.25.65) alcanzable${NC}" || \
  echo -e "${RED}✗ Backup (172.17.25.65) NO alcanzable${NC}"

# Paso 3: Configurar Master + Backup
echo -e "${YELLOW}[3/4] Configurando pfSense Master y Backup...${NC}"
echo "Esto puede tomar 10-15 minutos..."

ansible-playbook -i "$INVENTORY" playbooks/routers/pfsense/site.yml

echo -e "${GREEN}✓ pfSense configurado correctamente${NC}"

# Paso 4: Servidores Internet
echo -e "${YELLOW}[4/4] Habilitando internet para VLAN Servidores...${NC}"
ansible-playbook -i "$INVENTORY" playbooks/routers/pfsense/allow_servidores_internet.yml
echo -e "${GREEN}✓ Internet habilitado${NC}"

echo ""
echo "=========================================="
echo -e "${GREEN}CONFIGURACIÓN COMPLETADA${NC}"
echo "=========================================="
echo "Acceso Web:"
echo "  Master:  https://172.17.25.64"
echo "  Backup:  https://172.17.25.65"
echo ""
echo "Verificar:"
echo "  1. Status → CARP (failover)"
echo "  2. Status → Gateways"
echo "  3. ping 192.168.10.1 (VIP Servidores)"
echo "=========================================="
