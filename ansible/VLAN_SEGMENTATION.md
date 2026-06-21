# Segmentación de Red por VLANs con VLSM - NORCOM

## Esquema de VLANs con VLSM (Variable Length Subnet Masking)

| VLAN ID | Nombre | Red VLSM | Máscara | Gateway (VIP) | Hosts Útiles | Rango Usable | Propósito |
|---------|--------|----------|---------|---------------|--------------|--------------|-----------|
| **10** | Servidores | 192.168.10.0/26 | 255.255.255.192 | 192.168.10.1 | 62 | .1 - .62 | Infraestructura de servicios (DC, DNS, File Server, Mail) |
| **20** | Administración | 192.168.20.0/25 | 255.255.255.128 | 192.168.20.1 | 126 | .1 - .126 | Personal administrativo con acceso completo |
| **30** | TI | 192.168.30.0/26 | 255.255.255.192 | 192.168.30.1 | 62 | .1 - .62 | Departamento de TI con acceso total a infraestructura |
| **40** | Ventas | 192.168.40.0/25 | 255.255.255.128 | 192.168.40.1 | 126 | .1 - .126 | Departamento de ventas con acceso limitado |

### Justificación VLSM

**¿Por qué VLSM?**
- **Eficiencia:** Optimiza el uso del espacio IPv4 según necesidades reales
- **Broadcast reducido:** Dominios más pequeños = menor tráfico broadcast
- **Escalabilidad:** Permite agregar más VLANs en el futuro (50, 60, 70...)
- **Mejor segmentación:** Tamaños lógicos según el propósito de cada VLAN

**Estrategia aplicada (VLSM Conservador):**
- **VLANs pequeñas** (10, 30): `/26` = 62 hosts → Servidores y equipos técnicos
- **VLANs medianas** (20, 40): `/25` = 126 hosts → Departamentos con potencial crecimiento

## Desglose Detallado por VLAN

## Políticas de Acceso Inter-VLAN

### VLAN 10 - Servidores (192.168.10.0/26)
**Subred:** 192.168.10.0/26 (255.255.255.192)  
**Rango útil:** 192.168.10.1 - 192.168.10.62 (62 hosts)  
**Gateway/VIP:** 192.168.10.1  
**Router Master:** 192.168.10.2  
**Router Backup:** 192.168.10.3  
**Broadcast:** 192.168.10.63

**Asignación de IPs:**
```
192.168.10.1   - Gateway VIP (VRRP)
192.168.10.2   - Router Master Interface
192.168.10.3   - Router Backup Interface
192.168.10.5   - Domain Controller (DC1) + DNS Primary
192.168.10.6   - DNS Secondary (BIND9)
192.168.10.7   - File Server (Samba + AD)
192.168.10.9   - Mail Server (iRedMail)
192.168.10.10  - Zabbix Monitoring (AlmaLinux)
192.168.10.11-62 - Servidores futuros (espacio para 52 hosts adicionales)
```

**Servicios alojados:**
- Domain Controller (192.168.10.5)
- DNS Secundario (192.168.10.6)
- File Server (192.168.10.7)
- Mail Server (192.168.10.9)
- Zabbix Monitoring (192.168.10.10)

**Acceso:**
- ✅ Recibe conexiones de: Administración (VLAN 20), TI (VLAN 30), Ventas (VLAN 40)
- ✅ Responde a solicitudes establecidas de todas las VLANs
- ❌ No inicia conexiones hacia VLANs de usuarios

**Justificación /26:** Solo hay 4-5 servidores actuales, con /26 hay espacio para 50+ servidores adicionales.

### VLAN 20 - Administración (192.168.20.0/25)
**Subred:** 192.168.20.0/25 (255.255.255.128)  
**Rango útil:** 192.168.20.1 - 192.168.20.126 (126 hosts)  
**Gateway/VIP:** 192.168.20.1  
**Router Master:** 192.168.20.2  
**Router Backup:** 192.168.20.3  
**Broadcast:** 192.168.20.127

**Asignación de IPs:**
```
192.168.20.1     - Gateway VIP (VRRP)
192.168.20.2     - Router Master Interface
192.168.20.3     - Router Backup Interface
192.168.20.4-49  - IPs estáticas reservadas (administradores, equipos críticos)
192.168.20.50-120 - Pool DHCP (71 IPs dinámicas)
192.168.20.121-126 - Reserva futura
```

**DHCP Scope:**
- **Rango:** 192.168.20.50 - 192.168.20.120 (71 IPs)
- **DNS:** 192.168.10.5, 192.168.10.6
- **Lease:** 1 día

**Permisos:** Acceso completo a toda la red

**Acceso:**
- ✅ Puede acceder a: Servidores (VLAN 10), TI (VLAN 30), Ventas (VLAN 40)
- ✅ Acceso bidireccional con todas las VLANs
- ✅ Acceso a Internet vía dual-WAN
- 🔑 Administración SSH a routers permitida desde esta VLAN

**Justificación /25:** Departamento administrativo con ~40-60 usuarios, /25 permite crecimiento hasta 126 hosts.

### VLAN 30 - TI (192.168.30.0/26)
**Subred:** 192.168.30.0/26 (255.255.255.192)  
**Rango útil:** 192.168.30.1 - 192.168.30.62 (62 hosts)  
**Gateway/VIP:** 192.168.30.1  
**Router Master:** 192.168.30.2  
**Router Backup:** 192.168.30.3  
**Broadcast:** 192.168.30.63

**Asignación de IPs:**
```
192.168.30.1     - Gateway VIP (VRRP)
192.168.30.2     - Router Master Interface
192.168.30.3     - Router Backup Interface
192.168.30.4-29  - IPs estáticas (equipos de TI, estaciones de trabajo)
192.168.30.30-60 - Pool DHCP (31 IPs dinámicas)
192.168.30.61-62 - Reserva
```

**DHCP Scope:**
- **Rango:** 192.168.30.30 - 192.168.30.60 (31 IPs)
- **DNS:** 192.168.10.5, 192.168.10.6
- **Lease:** 1 día

**Permisos:** Acceso completo a infraestructura

**Acceso:**
- ✅ Puede acceder a: Servidores (VLAN 10), Administración (VLAN 20), Ventas (VLAN 40)
- ✅ Acceso bidireccional con todas las VLANs
- ✅ Acceso a Internet vía dual-WAN
- 🔧 Soporte técnico y mantenimiento de toda la infraestructura

**Justificación /26:** Equipo técnico pequeño (~10-20 personas) + dispositivos de prueba, /26 es suficiente con margen.

### VLAN 40 - Ventas (192.168.40.0/25)
**Subred:** 192.168.40.0/25 (255.255.255.128)  
**Rango útil:** 192.168.40.1 - 192.168.40.126 (126 hosts)  
**Gateway/VIP:** 192.168.40.1  
**Router Master:** 192.168.40.2  
**Router Backup:** 192.168.40.3  
**Broadcast:** 192.168.40.127

**Asignación de IPs:**
```
192.168.40.1     - Gateway VIP (VRRP)
192.168.40.2     - Router Master Interface
192.168.40.3     - Router Backup Interface
192.168.40.4-49  - IPs estáticas reservadas (supervisores, equipos fijos)
192.168.40.50-120 - Pool DHCP (71 IPs dinámicas)
192.168.40.121-126 - Reserva futura
```

**DHCP Scope:**
- **Rango:** 192.168.40.50 - 192.168.40.120 (71 IPs)
- **DNS:** 192.168.10.5, 192.168.10.6
- **Lease:** 1 día

**Permisos:** Acceso restringido solo a servicios

**Acceso:**
- ✅ Puede acceder a: Servidores (VLAN 10) - compartidos de archivos, correo, AD
- ✅ Acceso a Internet vía dual-WAN
- ❌ **Bloqueado** hacia: Administración (VLAN 20), TI (VLAN 30)
- ⚠️ Solo puede consumir servicios, no gestionar infraestructura

**Justificación /25:** Departamento de ventas en crecimiento (~50-80 usuarios), /25 permite hasta 126 hosts.

## Matriz de Acceso

| Origen → Destino | VLAN 10<br>Servidores | VLAN 20<br>Administración | VLAN 30<br>TI | VLAN 40<br>Ventas | Internet |
|------------------|:---------------------:|:--------------------------:|:-------------:|:-----------------:|:--------:|
| **VLAN 10** Servidores | ✅ | ❌ (solo respuestas) | ❌ (solo respuestas) | ❌ (solo respuestas) | ✅ |
| **VLAN 20** Administración | ✅ | ✅ | ✅ | ✅ | ✅ |
| **VLAN 30** TI | ✅ | ✅ | ✅ | ✅ | ✅ |
| **VLAN 40** Ventas | ✅ | ❌ | ❌ | ✅ | ✅ |

**Leyenda:**
- ✅ Permitido - Tráfico puede fluir
- ❌ Bloqueado - Tráfico se descarta (DROP)
- ❌ (solo respuestas) - Solo tráfico ESTABLISHED/RELATED permitido

## Configuración DHCP con VLSM

### Scopes configurados en DC (192.168.10.5)

| VLAN | Scope ID | Subnet Mask | Rango DHCP | IPs Disponibles | DNS Servers | Lease Time |
|------|----------|-------------|------------|-----------------|-------------|------------|
| 20 | 192.168.20.0 | 255.255.255.128 (/25) | .50 - .120 | 71 | 192.168.10.5, 192.168.10.6 | 1 día |
| 30 | 192.168.30.0 | 255.255.255.192 (/26) | .30 - .60 | 31 | 192.168.10.5, 192.168.10.6 | 1 día |
| 40 | 192.168.40.0 | 255.255.255.128 (/25) | .50 - .120 | 71 | 192.168.10.5, 192.168.10.6 | 1 día |

**Notas importantes:**
- VLAN 10 (Servidores) usa IPs estáticas exclusivamente, no tiene scope DHCP
- Los rangos DHCP evitan las primeras IPs reservadas para infraestructura (.1-.49 típicamente)
- Las máscaras variables permiten optimizar el uso de IPs según necesidad real

## Grupos y Recursos Compartidos

### Active Directory

**Grupos de seguridad:**
- `Administracion` - Personal administrativo
- `TI` - Departamento de tecnología
- `Ventas` - Equipo comercial

### File Server (Samba)

**Recursos compartidos:**
- `\\fileserver1\CompartidoAdmin` - Acceso: grupo `Administracion`
- `\\fileserver1\CompartidoTI` - Acceso: grupo `TI`
- `\\fileserver1\CompartidoVentas` - Acceso: grupo `Ventas`

## Implementación Técnica

### Firewall (iptables)
Las reglas de firewall están implementadas en:
- `ubuntu_router_master.yml` (Router principal - prioridad 200)
- `ubuntu_router_backup.yml` (Router respaldo - prioridad 100)

**Política por defecto:** DROP (todo bloqueado excepto lo explícitamente permitido)

**Reglas clave:**
1. NAT Masquerade hacia ambos WAN
2. Forward desde VLANs hacia Internet
3. Políticas inter-VLAN según matriz de acceso
4. VRRP permitido entre routers para HA
5. DHCP relay habilitado para VLANs cliente

### Alta Disponibilidad (VRRP) con VLSM
Cada VLAN tiene su propia instancia VRRP con máscaras variables:

| VLAN | VRRP ID | VIP | Máscara | Master IP | Backup IP | Prioridad Master | Prioridad Backup |
|------|---------|-----|---------|-----------|-----------|------------------|------------------|
| 10 | 10 | 192.168.10.1/26 | 255.255.255.192 | 192.168.10.2 | 192.168.10.3 | 200 | 100 |
| 20 | 20 | 192.168.20.1/25 | 255.255.255.128 | 192.168.20.2 | 192.168.20.3 | 200 | 100 |
| 30 | 30 | 192.168.30.1/26 | 255.255.255.192 | 192.168.30.2 | 192.168.30.3 | 200 | 100 |
| 40 | 40 | 192.168.40.1/25 | 255.255.255.128 | 192.168.40.2 | 192.168.40.3 | 200 | 100 |

**Failover:** Automático si router master falla  
**Tiempo de convergencia:** ~1-3 segundos  
**Autenticación:** PASS (shared secret: VRRP_PASS_2024)

## Modificaciones Realizadas

### Archivos actualizados:
1. **`post_dc.yml`** - Scopes DHCP actualizados para VLAN 20, 30, 40
2. **`ad_users.yml`** - Grupos y usuarios por departamento
3. **`ubuntu_file_server.yml`** - Múltiples shares por grupo
4. **`ubuntu_router_master.yml`** - VLAN 40 agregada + nuevas políticas firewall
5. **`ubuntu_router_backup.yml`** - VLAN 40 agregada + nuevas políticas firewall

### Cambios en segmentación:

**Fase 1: Reorganización de VLANs**
| Antes | Después |
|-------|---------|
| VLAN 10: Servidores (/24) | VLAN 10: Servidores (/24) |
| VLAN 20: Trabajadores (/24) | VLAN 20: Administración (/24) |
| VLAN 30: Invitados WiFi (/24) | VLAN 30: TI (/24) |
| - | VLAN 40: Ventas (/24) - **NUEVA** |

**Fase 2: Implementación VLSM**
| VLAN | Antes | Después | Ahorro |
|------|-------|---------|--------|
| VLAN 10 | 192.168.10.0/24 (254 hosts) | 192.168.10.0/26 (62 hosts) | 192 IPs liberadas |
| VLAN 20 | 192.168.20.0/24 (254 hosts) | 192.168.20.0/25 (126 hosts) | 128 IPs liberadas |
| VLAN 30 | 192.168.30.0/24 (254 hosts) | 192.168.30.0/26 (62 hosts) | 192 IPs liberadas |
| VLAN 40 | 192.168.40.0/24 (254 hosts) | 192.168.40.0/25 (126 hosts) | 128 IPs liberadas |

**Beneficio total:** 640 IPs liberadas para futuras VLANs (50, 60, 70, 80, etc.)

## Espacio disponible para expansión

Gracias a VLSM, ahora tienes espacio para crear nuevas subredes:

```
USADO:
192.168.10.0/26   (VLAN 10 - Servidores)
192.168.20.0/25   (VLAN 20 - Administración)
192.168.30.0/26   (VLAN 30 - TI)
192.168.40.0/25   (VLAN 40 - Ventas)

DISPONIBLE PARA FUTURO:
192.168.10.64/26  - Puede ser VLAN 11 (Servidores DMZ)
192.168.10.128/25 - Puede ser VLAN 12-13
192.168.20.128/25 - Puede ser VLAN 21 (Administración remota)
192.168.30.64/26  - Puede ser VLAN 31 (Lab/Testing)
192.168.30.128/25 - Puede ser VLAN 32-33
192.168.40.128/25 - Puede ser VLAN 41 (Ventas remoto)
192.168.50.0/24   - VLANs 50-59 libres
192.168.60.0/24   - VLANs 60-69 libres
...y así sucesivamente hasta 192.168.255.0/24
```

## Cálculo VLSM - Referencia Técnica

### Tabla de Subredes CIDR

| CIDR | Máscara | Hosts Útiles | Broadcast | Ideal para |
|------|---------|--------------|-----------|------------|
| /30 | 255.255.255.252 | 2 | 1 | Enlaces punto a punto |
| /29 | 255.255.255.248 | 6 | 1 | Subredes muy pequeñas |
| /28 | 255.255.255.240 | 14 | 1 | Redes IoT, cámaras |
| /27 | 255.255.255.224 | 30 | 1 | Equipos técnicos pequeños |
| /26 | 255.255.255.192 | 62 | 1 | **Servidores, TI** ✅ |
| /25 | 255.255.255.128 | 126 | 1 | **Admin, Ventas** ✅ |
| /24 | 255.255.255.0 | 254 | 1 | Redes departamentales grandes |

### Cálculos aplicados:

**VLAN 10 (/26):**
- Network: 192.168.10.0
- First usable: 192.168.10.1
- Last usable: 192.168.10.62
- Broadcast: 192.168.10.63
- Next subnet: 192.168.10.64

**VLAN 20 (/25):**
- Network: 192.168.20.0
- First usable: 192.168.20.1
- Last usable: 192.168.20.126
- Broadcast: 192.168.20.127
- Next subnet: 192.168.20.128

**VLAN 30 (/26):**
- Network: 192.168.30.0
- First usable: 192.168.30.1
- Last usable: 192.168.30.62
- Broadcast: 192.168.30.63
- Next subnet: 192.168.30.64

**VLAN 40 (/25):**
- Network: 192.168.40.0
- First usable: 192.168.40.1
- Last usable: 192.168.40.126
- Broadcast: 192.168.40.127
- Next subnet: 192.168.40.128
