#!/bin/bash
# Setup del nodo de control Ansible - Ubuntu Server 24.04
# Ejecutar desde la raiz del proyecto: bash scripts/linux/setup_ansible_node.sh
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; }
step()    { echo -e "\n${BOLD}${YELLOW}==> $*${NC}"; }

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║     NORCOM - Setup Nodo de Control Ansible       ║"
echo "║              Ubuntu Server 24.04                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Verificar que se ejecuta desde la raiz del proyecto ─────────────────────
if [[ ! -f "ansible.cfg" || ! -d "inventory" || ! -d "playbooks" ]]; then
    error "Ejecutar desde la raiz del proyecto ansible_DC/"
    echo "  cd /ruta/a/ansible_DC && bash scripts/linux/setup_ansible_node.sh"
    exit 1
fi

PROJECT_DIR=$(pwd)
REQUIREMENTS_FILE="playbooks/routers/requirements.yml"
VAULT_PASS_FILE=".vault_pass"
ANSIBLE_MIN_VERSION="2.15"

# ─── 1. Dependencias del sistema ─────────────────────────────────────────────
step "1/6  Instalando dependencias del sistema"

sudo apt-get update -qq
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    sshpass \
    git \
    curl \
    libssl-dev \
    libffi-dev \
    build-essential \
    krb5-user \
    libkrb5-dev > /dev/null

success "Dependencias del sistema instaladas"

# ─── 2. Ansible via pipx (método recomendado Ubuntu 24.04) ───────────────────
step "2/6  Instalando Ansible"

sudo apt-get install -y pipx > /dev/null
pipx ensurepath > /dev/null

# Recargar PATH para que pipx sea visible
export PATH="$HOME/.local/bin:$PATH"

if command -v ansible &>/dev/null; then
    CURRENT_VERSION=$(ansible --version | head -1 | grep -oP '\d+\.\d+')
    info "Ansible ya instalado: versión $CURRENT_VERSION"
else
    pipx install --include-deps ansible
    export PATH="$HOME/.local/bin:$PATH"
    success "Ansible instalado: $(ansible --version | head -1)"
fi

# ─── 3. Dependencias Python para los módulos del proyecto ────────────────────
step "3/6  Instalando dependencias Python"

# pywinrm - para gestionar Windows via WinRM
# pyvmomi - para gestionar ESXi/vSphere
# netaddr  - para cálculos de red (ansible.utils)
# jmespath - para filtros JSON en playbooks
pipx inject ansible \
    pywinrm \
    pyvmomi \
    netaddr \
    jmespath \
    requests-ntlm > /dev/null

success "Dependencias Python instaladas (pywinrm, pyvmomi, netaddr, jmespath)"

# ─── 4. Colecciones Ansible ───────────────────────────────────────────────────
step "4/6  Instalando colecciones Ansible"

info "Instalando desde $REQUIREMENTS_FILE..."
ansible-galaxy collection install -r "$REQUIREMENTS_FILE" --force

# Colección de Windows y POSIX (no están en requirements pero son necesarias)
ansible-galaxy collection install \
    ansible.windows \
    ansible.posix \
    community.vmware > /dev/null

success "Colecciones instaladas:"
ansible-galaxy collection list 2>/dev/null | grep -E "ansible\.|community\.|pfsensible\." | \
    awk '{printf "        %-40s %s\n", $1, $2}'

# ─── 5. Vault password ───────────────────────────────────────────────────────
step "5/6  Configurando Ansible Vault"

if [[ -f "$VAULT_PASS_FILE" ]]; then
    warn "El archivo $VAULT_PASS_FILE ya existe, no se sobreescribe."
else
    echo ""
    echo -e "${YELLOW}Ingresá la contraseña del vault (se guarda en .vault_pass):${NC}"
    read -r -s -p "  Vault password: " VAULT_PASSWORD
    echo ""

    if [[ -z "$VAULT_PASSWORD" ]]; then
        warn "Contraseña vacía — creando .vault_pass en blanco. Editalo luego."
        touch "$VAULT_PASS_FILE"
    else
        echo "$VAULT_PASSWORD" > "$VAULT_PASS_FILE"
    fi

    chmod 600 "$VAULT_PASS_FILE"
    success "Archivo $VAULT_PASS_FILE creado (permisos 600)"
fi

# ─── 6. SSH Key ───────────────────────────────────────────────────────────────
step "6/6  Configurando SSH"

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
    warn "SSH key ya existe en $SSH_KEY"
else
    ssh-keygen -t ed25519 -C "ansible-norcom@$(hostname)" -f "$SSH_KEY" -N ""
    success "SSH key creada: $SSH_KEY"
fi

echo ""
info "Clave pública para distribuir a los hosts:"
echo -e "${CYAN}$(cat "${SSH_KEY}.pub")${NC}"
echo ""
info "Para distribuir la clave a un host Linux:"
echo "  ssh-copy-id -i ${SSH_KEY}.pub usuario@<ip_del_host>"

# ─── Verificación final ───────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}         SETUP COMPLETADO EXITOSAMENTE            ${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════${NC}\n"

echo "  Versiones instaladas:"
echo "    Ansible : $(ansible --version | head -1)"
echo "    Python  : $(python3 --version)"
echo ""
echo "  Proyecto : $PROJECT_DIR"
echo "  Vault    : $VAULT_PASS_FILE"
echo "  SSH key  : $SSH_KEY"
echo ""
echo "  Próximos pasos:"
echo "    1. Distribuir la SSH key a los hosts Linux"
echo "    2. Verificar conectividad:"
echo "       ansible all -m ping"
echo "    3. Verificar solo un grupo:"
echo "       ansible ubuntu_routers -m ping"
echo "       ansible pfsense_routers -m ping"
echo "       ansible windows -m win_ping"
echo ""
echo "  Scripts disponibles:"
echo "    bash scripts/linux/setup_pfsense.sh    → Configurar pfSense"
echo ""

# Advertir si PATH no persiste
if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    warn "Agregá esto a tu ~/.bashrc para que el PATH persista:"
    echo '    export PATH="$HOME/.local/bin:$PATH"'
fi
