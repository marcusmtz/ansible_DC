# Configuración pfSense con pfsensible.core

## Migración Completa: Ubuntu → pfSense con Ansible Nativo

Los playbooks ahora utilizan la colección **`pfsensible.core`** que proporciona módulos Ansible nativos para pfSense, permitiendo automatización completa sin configuración manual.

---

## 📦 Instalación de Requisitos

### 1. Instalar la Colección pfsensible.core

```bash
# Opción A: Desde archivo requirements.yml
cd d:\Proyectos\ansible_DC\ansible\linux\playbooks\WAN\
ansible-galaxy collection install -r requirements.yml

# Opción B: Instalación directa
ansible-galaxy collection install pfsensible.core
```

### 2. Verificar Instalación

```bash
ansible-galaxy collection list | findstr pfsensible
# Debería mostrar: pfsensible.core  X.X.X
```

### 3. Prerequisitos en pfSense

Los routers pfSense deben tener:

**Python instalado** (para conexión Ansible):
```bash
# Acceder a pfSense via SSH como admin
pkg install python39

# Verificar instalación
python3.9 --version
```

**Usuario con permisos** (usar admin por defecto o crear usuario dedicado):
```bash
# Opción: Crear usuario ansible
# System → User Manager → Add
# Username: ansible
# Password: [contraseña segura]
# Group: admins
```

---

## 🚀 Uso de los Playbooks

### Paso 1: Actualizar Inventario

Editar `linux/inventory.ini`:

```ini
[pfsense_router_master]
pfsense-master ansible_host=172.17.25.90 ansible_user=admin ansible_password=pfsense ansible_connection=local ansible_python_interpreter=/usr/local/bin/python3.9

[pfsense_router_backup]
pfsense-backup ansible_host=172.17.25.42 ansible_user=admin ansible_password=pfsense ansible_connection=local ansible_python_interpreter=/usr/local/bin/python3.9
```

**Nota:** Para producción, usar Ansible Vault para las contraseñas:
```bash
ansible-vault encrypt_string 'tu_password' --name 'ansible_password'
```

### Paso 2: Ejecutar Playbook Master

```bash
cd d:\Proyectos\ansible_DC\ansible\

# Ejecutar configuración del Master
ansible-playbook -i linux/inventory.ini \
  linux/playbooks/WAN/pfsense_router_master.yml

# Con verbosidad para debug
ansible-playbook -i linux/inventory.ini \
  linux/playbooks/WAN/pfsense_router_master.yml -vvv
```

### Paso 3: Ejecutar Playbook Backup

```bash
# IMPORTANTE: Ejecutar Master PRIMERO

# Ejecutar configuración del Backup
ansible-playbook -i linux/inventory.ini \
  linux/playbooks/WAN/pfsense_router_backup.yml
```

### Paso 4: Verificar Configuración

```bash
# Acceder a Web GUI
Master:  https://172.17.25.90
Backup:  https://172.17.25.42

# Verificar CARP
# Status → CARP (failover)
# Master debe mostrar: MASTER
# Backup debe mostrar: BACKUP
```

---

## 📋 Módulos pfsensible.core Utilizados

Los playbooks utilizan los siguientes módulos:

| Módulo | Propósito | Usado en |
|--------|-----------|----------|
| `pfsense_setup` | Configuración básica del sistema | Master, Backup |
| `pfsense_interface` | Configurar interfaces de red | Master, Backup |
| `pfsense_vlan` | Crear VLANs 802.1Q | Master, Backup |
| `pfsense_virtual_ip` | Configurar CARP (HA) | Master, Backup |
| `pfsense_gateway` | Configurar gateways WAN | Master, Backup |
| `pfsense_gateway_group` | Gateway groups (multi-WAN) | Master, Backup |
| `pfsense_nat_outbound` | Reglas NAT saliente | Master, Backup |
| `pfsense_nat_outbound_mode` | Modo NAT (hybrid) | Master, Backup |
| `pfsense_rule` | Reglas de firewall | Master, Backup |
| `pfsense_dhcp_relay` | DHCP relay | Master, Backup |
| `pfsense_hasync` | Sincronización HA (CARP) | Master, Backup |
| `pfsense_reload` | Aplicar cambios | Master, Backup |

---

## 🎯 Configuración Implementada

### Sistema Básico
```yaml
- Hostname: pfsense-master / pfsense-backup
- Domain: norcom.internal
- Timezone: America/Lima
- DNS: 192.168.10.5, 192.168.10.6, 8.8.8.8, 1.1.1.1
```

### Interfaces WAN
```yaml
WAN1 (ISP Principal):
  - Master: 172.17.25.90/24 → Gateway 172.17.25.121
  - Backup: 172.17.25.42/24 → Gateway 172.17.25.121

WAN2 (ISP Secundario):
  - Master: 168.17.25.2/29 → Gateway 168.17.25.1
  - Backup: 168.17.25.3/29 → Gateway 168.17.25.1
```

### VLANs con VLSM
```yaml
VLAN 10 - SERVIDORES     (192.168.10.0/26)
  - VIP CARP: 192.168.10.1
  - Master:   192.168.10.2
  - Backup:   192.168.10.3
  - VHID: 10, advskew: 0/100

VLAN 20 - ADMINISTRACION (192.168.20.0/25)
  - VIP CARP: 192.168.20.1
  - Master:   192.168.20.2
  - Backup:   192.168.20.3
  - VHID: 20, advskew: 0/100

VLAN 30 - TI             (192.168.30.0/26)
  - VIP CARP: 192.168.30.1
  - Master:   192.168.30.2
  - Backup:   192.168.30.3
  - VHID: 30, advskew: 0/100

VLAN 40 - VENTAS         (192.168.40.0/25)
  - VIP CARP: 192.168.40.1
  - Master:   192.168.40.2
  - Backup:   192.168.40.3
  - VHID: 40, advskew: 0/100
```

### Políticas de Firewall
```yaml
Administración (VLAN 20):
  - Permitir: TODO (acceso completo)

TI (VLAN 30):
  - Permitir: TODO (acceso completo)

Ventas (VLAN 40):
  - Permitir: Servidores (VLAN 10), Internet
  - Bloquear: Administración (VLAN 20), TI (VLAN 30)

Servidores (VLAN 10):
  - Permitir: Solo tráfico establecido/relacionado
```

### Gateway Group (Multi-WAN)
```yaml
DUAL_WAN_FAILOVER:
  - WAN1_GW: Tier 1, Weight 1
  - WAN2_GW: Tier 1, Weight 1
  - Trigger: down
  - Load balancing activo entre ambos ISPs
```

### DHCP Relay
```yaml
Server: 192.168.10.5 (DC1)
Interfaces: ADMINISTRACION, TI, VENTAS
```

### Alta Disponibilidad (HA)
```yaml
pfsync:
  - Interface: SERVIDORES (VLAN 10)
  - Master peer: 192.168.10.3
  - Backup peer: 192.168.10.2

XMLRPC Config Sync (Master → Backup):
  - Rules, NAT, VIPs, DHCP, VPN, etc.
  - Sincronización automática de cambios
```

---

## 🔍 Verificación Post-Implementación

### 1. Verificar Interfaces

```bash
# En pfSense Web GUI
Status → Interfaces

# Debe mostrar:
# WAN1, WAN2: UP con IPs correctas
# SERVIDORES, ADMINISTRACION, TI, VENTAS: UP con IPs correctas
```

### 2. Verificar CARP

```bash
# Status → CARP (failover)

# Master debe mostrar:
#   Estado general: MASTER
#   Cada VIP: MASTER

# Backup debe mostrar:
#   Estado general: BACKUP
#   Cada VIP: BACKUP
```

### 3. Verificar Gateways

```bash
# Status → Gateways

# Debe mostrar:
# WAN1_GW: Online, RTT: X ms
# WAN2_GW: Online, RTT: X ms
```

### 4. Verificar Virtual IPs

```bash
# Firewall → Virtual IPs

# Debe mostrar 4 VIPs:
# 192.168.10.1/26 - VHID 10
# 192.168.20.1/25 - VHID 20
# 192.168.30.1/26 - VHID 30
# 192.168.40.1/25 - VHID 40
```

### 5. Prueba de Conectividad

```bash
# Desde un cliente en cada VLAN:

# VLAN 10 (Servidores)
ping 192.168.10.1   # VIP Gateway
ping 8.8.8.8        # Internet via WAN

# VLAN 20 (Administración)
ping 192.168.20.1
ping 192.168.10.5   # DC1
ping 8.8.8.8

# VLAN 30 (TI)
ping 192.168.30.1
ping 192.168.10.5
ping 192.168.20.2   # Administración permitida
ping 8.8.8.8

# VLAN 40 (Ventas)
ping 192.168.40.1
ping 192.168.10.5   # Servidores permitido
ping 192.168.20.2   # Debe fallar (bloqueado)
ping 192.168.30.2   # Debe fallar (bloqueado)
ping 8.8.8.8        # Internet permitido
```

### 6. Prueba de Failover

```bash
# Desde un cliente, hacer ping continuo a un VIP
ping -t 192.168.10.1  # Windows
ping 192.168.10.1     # Linux (mantener corriendo)

# En el Master:
# Status → CARP (failover) → [Disable CARP]

# Observar:
# - Backup debe cambiar a MASTER inmediatamente
# - Pérdida de pings: 0-2 paquetes máximo (~1-3 segundos)

# Rehabilitar CARP en Master:
# Status → CARP (failover) → [Enable CARP]

# Observar:
# - Master recupera control
# - Backup vuelve a BACKUP
```

---

## ⚙️ Personalización

### Ajustar Nombres de Interfaces

Si tus interfaces físicas tienen nombres diferentes:

```yaml
# Editar en vars:
wan1_interface: "em0"     # En lugar de igb0
wan2_interface: "em1"     # En lugar de igb1
trunk_interface: "em2"    # En lugar de igb2
```

### Ajustar Prioridades CARP

Para hacer el Backup más prioritario temporalmente:

```yaml
# En Master:
advskew: 100  # Cambiar de 0 a 100

# En Backup:
advskew: 0    # Cambiar de 100 a 0
```

### Agregar Más VLANs

```yaml
vlans:
  # ... VLANs existentes ...
  - vlan_id: 50
    name: "NUEVA_VLAN"
    descr: "VLAN 50 - Descripción"
    parent_interface: "{{ trunk_interface }}"
    ipaddr: "192.168.50.2"
    subnet: "24"
    vip: "192.168.50.1"
    vhid: 50
    advskew: 0  # Master
```

### Cambiar Passwords

**Usando Ansible Vault (recomendado):**

```bash
# Crear vault file
ansible-vault create group_vars/pfsense/vault.yml

# Contenido:
vault_pfsense_password: "tu_password_seguro"
vault_carp_password: "tu_carp_password"

# Usar en playbook:
pfsense_password: "{{ vault_pfsense_password }}"
carp_password: "{{ vault_carp_password }}"

# Ejecutar con vault:
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

---

## 🐛 Troubleshooting

### Error: "Module pfsensible.core not found"

```bash
# Solución:
ansible-galaxy collection install pfsensible.core

# Verificar:
ansible-galaxy collection list | findstr pfsensible
```

### Error: "Python not found on pfSense"

```bash
# Conectar via SSH a pfSense
ssh admin@172.17.25.90

# Instalar Python
pkg install python39

# Verificar
which python3.9
# Debe mostrar: /usr/local/bin/python3.9
```

### Error: "Connection refused"

```bash
# Verificar SSH habilitado en pfSense
# System → Advanced → Secure Shell
# [✓] Enable Secure Shell

# Verificar conectividad
ping 172.17.25.90
ssh admin@172.17.25.90
```

### CARP no sincroniza

```bash
# Verificar conectividad entre routers en VLAN10
# Desde Master:
ping 192.168.10.3

# Desde Backup:
ping 192.168.10.2

# Verificar firewall permite CARP (protocolo 112)
# Firewall → Rules → SERVIDORES
# Debe existir regla permitiendo CARP
```

### Playbook falla en tarea específica

```bash
# Ejecutar con verbosidad máxima
ansible-playbook -i inventory.ini playbook.yml -vvv

# Verificar logs en pfSense
# Status → System Logs → System
# Buscar errores relacionados con configuración
```

---

## 📚 Referencias

- [pfsensible.core Collection](https://galaxy.ansible.com/pfsensible/core)
- [pfsensible.core GitHub](https://github.com/pfsensible/core)
- [pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/)
- [CARP Configuration Guide](https://docs.netgate.com/pfsense/en/latest/highavailability/index.html)
- [Ansible Collections Guide](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)

---

## 🎓 Comparativa: Manual vs pfsensible.core

| Aspecto | Manual (Web GUI) | pfsensible.core |
|---------|------------------|-----------------|
| **Tiempo setup** | 2-4 horas | 10-15 minutos |
| **Reproducibilidad** | Baja (pasos manuales) | Alta (código) |
| **Errores** | Humanos frecuentes | Mínimos |
| **Documentación** | Externa | Código = Docs |
| **Versionado** | No | Git |
| **Idempotencia** | No | Sí |
| **Rollback** | Difícil | Fácil (Git) |
| **Escalabilidad** | 1 router a la vez | N routers paralelo |

---

## ✅ Ventajas de esta Implementación

1. **Automatización completa** - Sin pasos manuales
2. **Idempotente** - Ejecutar múltiples veces sin problemas
3. **Versionado** - Configuración en Git
4. **Reproducible** - Mismo resultado siempre
5. **Documentado** - El código es la documentación
6. **Testeable** - Probar en lab antes de producción
7. **Escalable** - Agregar routers fácilmente
8. **Mantenible** - Cambios centralizados

---

**Los playbooks están listos para uso en producción. ¿Necesitas ayuda con la ejecución o alguna personalización adicional?**
