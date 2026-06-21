#!/bin/bash
# Script de instalación y ejecución rápida para pfSense con pfsensible.core

set -e  # Salir si hay error

echo "=========================================="
echo "Configuración Automatizada pfSense NORCOM"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar si estamos en el directorio correcto
if [ ! -f "requirements.yml" ]; then
    echo -e "${RED}Error: Ejecutar desde d:\Proyectos\ansible_DC\ansible\linux\playbooks\WAN\${NC}"
    exit 1
fi

# Paso 1: Instalar colección pfsensible.core
echo -e "${YELLOW}[1/4] Instalando colección pfsensible.core...${NC}"
ansible-galaxy collection install -r requirements.yml --force

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Colección instalada correctamente${NC}"
else
    echo -e "${RED}✗ Error instalando colección${NC}"
    exit 1
fi

echo ""

# Paso 2: Verificar conectividad a pfSense
echo -e "${YELLOW}[2/4] Verificando conectividad a pfSense...${NC}"

ping -c 2 172.17.25.90 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Master (172.17.25.90) alcanzable${NC}"
else
    echo -e "${RED}✗ Master (172.17.25.90) NO alcanzable${NC}"
    echo "Verificar red y continuar? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

ping -c 2 172.17.25.42 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backup (172.17.25.42) alcanzable${NC}"
else
    echo -e "${RED}✗ Backup (172.17.25.42) NO alcanzable${NC}"
    echo "Verificar red y continuar? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# Paso 3: Configurar Master
echo -e "${YELLOW}[3/4] Configurando pfSense Master...${NC}"
echo "Esto puede tomar 5-10 minutos..."
echo ""

cd ../../../..  # Ir a ansible/

ansible-playbook -i linux/inventory.ini \
    linux/playbooks/WAN/pfsense_router_master.yml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Master configurado correctamente${NC}"
else
    echo -e "${RED}✗ Error configurando Master${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Esperando 30 segundos para que Master aplique cambios...${NC}"
sleep 30

# Paso 4: Configurar Backup
echo -e "${YELLOW}[4/4] Configurando pfSense Backup...${NC}"
echo "Esto puede tomar 5-10 minutos..."
echo ""

ansible-playbook -i linux/inventory.ini \
    linux/playbooks/WAN/pfsense_router_backup.yml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backup configurado correctamente${NC}"
else
    echo -e "${RED}✗ Error configurando Backup${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}CONFIGURACIÓN COMPLETADA${NC}"
echo "=========================================="
echo ""
echo "Acceso Web:"
echo "  Master:  https://172.17.25.90"
echo "  Backup:  https://172.17.25.42"
echo ""
echo "Verificar:"
echo "  1. Status → CARP (failover)"
echo "  2. Status → Gateways"
echo "  3. Status → Interfaces"
echo ""
echo "Probar failover:"
echo "  1. ping -t 192.168.10.1 (desde cliente)"
echo "  2. Disable CARP en Master"
echo "  3. Verificar que Backup toma control"
echo ""
echo "=========================================="
