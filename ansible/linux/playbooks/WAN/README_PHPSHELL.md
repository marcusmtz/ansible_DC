# Playbooks pfSense MASTER y BACKUP - Configuración via PHPShell

## 📋 Descripción

Playbooks de Ansible completamente reescritos usando **pfsensible.core.pfsense_phpshell** como método principal de configuración. Esto proporciona control total sobre la configuración de pfSense sin depender de módulos nativos que pueden tener limitaciones.

## 🎯 Arquitectura

```
┌─────────────────────┐         ┌─────────────────────┐
│  pfSense MASTER     │         │  pfSense BACKUP     │
│  172.17.25.64       │◄───────►│  172.17.25.65       │
│  advskew=0          │  CARP   │  advskew=100        │
│  192.168.10.2       │  Sync   │  192.168.10.3       │
└─────────────────────┘         └─────────────────────┘
         │                               │
         │         Virtual IPs (CARP)    │
         ├───────────────────────────────┤
         │   192.168.10.1 (VLAN 10)     │
         │   192.168.20.1 (VLAN 20)     │
         │   192.168.30.1 (VLAN 30)     │
         │   192.168.40.1 (VLAN 40)     │
         └───────────────────────────────┘
```

## ✅ Componentes Configurados

### Via PHPShell

Todos los componentes se configuran usando `pfsense_phpshell`:

1. **Sistema Básico**
   - Hostname, domain, timezone
   - Servidores DNS
   - Servidores NTP

2. **Alias RFC1918**
   - Redes privadas (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)

3. **Interfaces WAN**
   - WAN1 (vmx0): 172.17.25.64/24 (MASTER) | 172.17.25.65/24 (BACKUP)
   - WAN2 (vmx2): 168.17.25.2/29 (MASTER) | 168.17.25.3/29 (BACKUP)
   - Gateways: WAN1_GW y WAN2_GW

4. **Gateway Group**
   - DUAL_WAN_FAILOVER (failover automático)

5. **VLANs (trunk vmx1)**
   - VLAN 10 - SERVIDORES (192.168.10.0/26)
   - VLAN 20 - ADMINISTRACION (192.168.20.0/25)
   - VLAN 30 - TI (192.168.30.0/26)
   - VLAN 40 - VENTAS (192.168.40.0/25)

6. **CARP Virtual IPs**
   - 4 VIPs (una por VLAN)
   - MASTER: advskew=0
   - BACKUP: advskew=100
   - Password compartido: CARP_PASS_2024

7. **NAT Outbound**
   - Modo Hybrid
   - Reglas para todas las VLANs hacia WAN1 y WAN2

8. **Reglas de Firewall**
   - VLAN 20 (Admin): Acceso completo
   - VLAN 30 (TI): Acceso completo
   - VLAN 40 (Ventas):
     - ❌ Bloqueado a Admin
     - ❌ Bloqueado a TI
     - ✅ Permitido a Servidores
     - ✅ Permitido a Internet (no RFC1918)
   - VLAN 10 (Servidores): Respuestas permitidas

9. **DHCP Relay**
   - Relay hacia 192.168.10.5
   - Interfaces: VLAN 20, 30, 40

10. **High Availability Sync**
    - **MASTER**: pfsync + XMLRPC (envía configuración al backup)
    - **BACKUP**: solo pfsync (recibe del master)

## 🔧 Variables Clave

### MASTER (pfsense_router_master.yml)
```yaml
pfsense_host: "172.17.25.64"
hostname: "pfsense-master"
ha_sync_peer: "192.168.10.3"  # IP del BACKUP
advskew: 0                      # Prioridad MASTER
```

### BACKUP (pfsense_router_backup.yml)
```yaml
pfsense_host: "172.17.25.65"
hostname: "pfsense-backup"
ha_sync_peer: "192.168.10.2"  # IP del MASTER
advskew: 100                    # Prioridad BACKUP
```

## 🚀 Ejecución

### Prerequisitos

1. Instalar colección pfsensible.core:
```bash
ansible-galaxy collection install -r requirements.yml
```

2. Configurar inventario con los hosts:
```ini
[pfsense_router_master]
pfsense-master ansible_host=172.17.25.64

[pfsense_router_backup]
pfsense-backup ansible_host=172.17.25.65
```

### Ejecutar Playbooks

```bash
# 1. Configurar MASTER primero
ansible-playbook -i ../../inventory.ini pfsense_router_master.yml

# 2. Configurar BACKUP después
ansible-playbook -i ../../inventory.ini pfsense_router_backup.yml
```

## ✔️ Verificación Post-Configuración

### En el MASTER (172.17.25.64)

1. **Status → CARP (Failover)**
   - ✅ Debe mostrar 4 VIPs en estado **MASTER**

2. **Status → Gateways**
   - ✅ WAN1_GW: Online
   - ✅ WAN2_GW: Online

3. **System → Routing → Gateway Groups**
   - ✅ DUAL_WAN_FAILOVER debe existir

4. **Firewall → Virtual IPs**
   - ✅ 4 VIPs tipo CARP
   - ✅ VHIDs: 10, 20, 30, 40
   - ✅ advskew: 0

5. **System → High Avail. Sync**
   - ✅ pfsync habilitado
   - ✅ XMLRPC Sync configurado hacia 192.168.10.3

### En el BACKUP (172.17.25.65)

1. **Status → CARP (Failover)**
   - ✅ Debe mostrar 4 VIPs en estado **BACKUP**

2. **Status → Gateways**
   - ✅ WAN1_GW: Online
   - ✅ WAN2_GW: Online

3. **Firewall → Virtual IPs**
   - ✅ 4 VIPs tipo CARP
   - ✅ VHIDs: 10, 20, 30, 40
   - ✅ advskew: 100

4. **System → High Avail. Sync**
   - ✅ pfsync habilitado (recibe del MASTER)

### Pruebas de Conectividad

```bash
# Desde un cliente en cualquier VLAN, hacer ping a las VIPs
ping 192.168.10.1  # VLAN Servidores
ping 192.168.20.1  # VLAN Admin
ping 192.168.30.1  # VLAN TI
ping 192.168.40.1  # VLAN Ventas

# Probar failover
# 1. En MASTER, ir a Status → CARP → Disable CARP
# 2. Los VIPs deben pasar automáticamente a BACKUP
# 3. El ping a las VIPs NO debe interrumpirse
```

## 🔄 Diferencias MASTER vs BACKUP

| Componente | MASTER | BACKUP |
|------------|--------|--------|
| **IP WAN1** | 172.17.25.64 | 172.17.25.65 |
| **IP WAN2** | 168.17.25.2 | 168.17.25.3 |
| **IP VLAN10** | 192.168.10.2 | 192.168.10.3 |
| **IP VLAN20** | 192.168.20.2 | 192.168.20.3 |
| **IP VLAN30** | 192.168.30.2 | 192.168.30.3 |
| **IP VLAN40** | 192.168.40.2 | 192.168.40.3 |
| **advskew** | 0 (MASTER) | 100 (BACKUP) |
| **HA Sync Peer** | 192.168.10.3 | 192.168.10.2 |
| **XMLRPC Sync** | ✅ Envía config | ❌ Solo recibe |
| **Estado CARP** | MASTER | BACKUP |

## 🎓 Ventajas del Enfoque PHPShell

### ✅ Ventajas

1. **Control Total**: Acceso directo al config.xml de pfSense
2. **Sin Limitaciones**: No dependemos de módulos incompletos
3. **Idempotencia**: Lógica de verificación incluida en cada tarea
4. **Flexibilidad**: Podemos configurar cualquier parámetro de pfSense
5. **Mantenibilidad**: Un solo método para todo

### ⚠️ Consideraciones

1. **Requiere conocimiento de PHP**: Hay que conocer la estructura de config.xml
2. **Validación Manual**: No hay validación automática de sintaxis
3. **Debugging**: Errores PHP pueden ser menos claros
4. **Versiones pfSense**: El código PHP debe ser compatible con la versión

## 📚 Recursos

- [pfSensible Core Collection](https://github.com/pfsensible/core)
- [pfSense Configuration Structure](https://docs.netgate.com/pfsense/en/latest/development/boot-commands.html)
- [CARP Documentation](https://docs.netgate.com/pfsense/en/latest/highavailability/index.html)

## 🆘 Troubleshooting

### Error: "No such file or directory: '/cf/conf/config.xml'"
**Solución**: Asegúrate de usar `connection: local` y pasar credenciales explícitas en cada módulo.

### CARP no se sincroniza
**Verificar**:
1. VHIDs coinciden en ambos pfSense
2. Password CARP es el mismo
3. Interfaces VLAN están UP
4. pfsync está habilitado

### Gateway Group no aparece
**Verificar**:
1. Ambos gateways existen
2. Gateways están Online
3. Revisar System → Routing → Gateway Groups

---

**Creado por**: Ansible Automation
**Fecha**: 2026-06-21
**Versión**: 1.0 (PHPShell Full)
