# Especificaciones de Hardware - VMs

## Resumen

| VM | vCPU | RAM | Disco | SO |
|---|---|---|---|---|
| pfSense Master | 2 | 4 GB | 20 GB | pfSense |
| pfSense Backup | 2 | 4 GB | 20 GB | pfSense |
| Ubuntu Router Master | 2 | 2 GB | 20 GB | Ubuntu Server |
| Ubuntu Router Backup | 2 | 2 GB | 20 GB | Ubuntu Server |
| Windows Server (DC) | 1 | 6 GB | 60 GB | Windows Server |
| Ubuntu DNS | 1 | 1 GB | 20 GB | Ubuntu Server |
| VoIP | 2 | 2 GB | 40 GB | - |
| File Server | 2 | 4 GB | 20 GB | Ubuntu Server |
| Mail Server | 2 | 4 GB | 20 GB | Ubuntu Server |
| Zabbix | 2 | 2 GB | 20 GB | Ubuntu Server |
| Ubuntu ISP2 | 1 | 2 GB | 10 GB | Ubuntu Server |

## Detalle por VM

### pfSense Master
- **Rol:** Router principal con firewall, NAT, CARP master
- **vCPU:** 2
- **RAM:** 4 GB
- **Disco:** 20 GB
- **Interfaces:** vmx0 (wan_1), vmx1 (lan_trunk), vmx2 (wan_2)

### pfSense Backup
- **Rol:** Router de respaldo con CARP backup
- **vCPU:** 2
- **RAM:** 4 GB
- **Disco:** 20 GB
- **Interfaces:** vmx0 (wan_1), vmx1 (lan_trunk), vmx2 (wan_2)

### Ubuntu Router Master
- **Rol:** Router principal Linux con VRRP master, NAT y trunk de VLANs
- **vCPU:** 2
- **RAM:** 2 GB
- **Disco:** 20 GB
- **IP:** 192.168.10.2
- **Interfaces:** ens34 (wan_1), ens35 (wan_2), ens36 (lan_trunk)

### Ubuntu Router Backup
- **Rol:** Router de respaldo Linux con VRRP backup
- **vCPU:** 2
- **RAM:** 2 GB
- **Disco:** 20 GB
- **IP:** 192.168.10.3
- **Interfaces:** ens34 (wan_1), ens35 (wan_2), ens36 (lan_trunk)

### Windows Server (DC)
- **Rol:** Domain Controller, DNS primario, DHCP
- **vCPU:** 1
- **RAM:** 6 GB
- **Disco:** 60 GB
- **Red:** vlan10_servers
- **IP:** 192.168.10.5

### Ubuntu DNS
- **Rol:** DNS secundario (BIND9)
- **vCPU:** 1
- **RAM:** 1 GB
- **Disco:** 20 GB
- **Red:** vlan10_servers
- **IP:** 192.168.10.6

### VoIP
- **Rol:** Servidor de telefonía IP
- **vCPU:** 2
- **RAM:** 2 GB
- **Disco:** 40 GB
- **Red:** vlan10_servers
- **IP:** (DHCP / por definir)

### File Server
- **Rol:** Servidor Samba integrado con AD
- **vCPU:** 2
- **RAM:** 4 GB
- **Disco:** 20 GB
- **Red:** vlan10_servers
- **IP:** 192.168.10.7

### Mail Server
- **Rol:** Servidor de correo iRedMail
- **vCPU:** 2
- **RAM:** 4 GB
- **Disco:** 20 GB
- **Red:** vlan10_servers
- **IP:** 192.168.10.9

### Zabbix
- **Rol:** Monitoreo de infraestructura (Zabbix 7.0 LTS)
- **vCPU:** 2
- **RAM:** 2 GB
- **Disco:** 20 GB
- **Red:** vlan10_servers
- **IP:** 192.168.10.10

### Ubuntu ISP2
- **Rol:** Router NAT para ISP secundario
- **vCPU:** 1
- **RAM:** 2 GB
- **Disco:** 10 GB
- **Interfaces:** ens34 (wan_1), ens35 (wan_2)

## Virtual Switches

### vSwitch0
- **Propósito:** WAN principal (ISP1)
- **Port groups:**

| Port Group | VLAN ID |
|---|---|
| wan_1 | - |

### vsw_isp2
- **Propósito:** WAN secundaria (ISP2)
- **Port groups:**

| Port Group | VLAN ID |
|---|---|
| wan_2 | - |

### vsw_lima
- **Propósito:** Red interna con segmentación VLAN
- **Port groups:**

| Port Group | VLAN ID | Uso |
|---|---|---|
| lan_trunk | 4095 | Trunk para routers pfSense (todas las VLANs) |
| vlan10_servers | 10 | Servidores de infraestructura |
| vlan20_admin | 20 | Administración |
| vlan30_ti | 30 | TI |
| vlan40_ventas | 40 | Ventas |

### Mapeo de interfaces por VM

| VM | Interfaz | Port Group | vSwitch |
|---|---|---|---|
| pfSense Master / Backup | vmx0 | wan_1 | vSwitch0 |
| pfSense Master / Backup | vmx1 | lan_trunk | vsw_lima |
| pfSense Master / Backup | vmx2 | wan_2 | vsw_isp2 |
| Windows DC | única NIC | vlan10_servers | vsw_lima |
| Ubuntu DNS | única NIC | vlan10_servers | vsw_lima |
| VoIP | única NIC | vlan10_servers | vsw_lima |
| File Server | única NIC | vlan10_servers | vsw_lima |
| Mail Server | única NIC | vlan10_servers | vsw_lima |
| Zabbix | única NIC | vlan10_servers | vsw_lima |
| Ubuntu Router Master / Backup | ens34 | wan_1 | vSwitch0 |
| Ubuntu Router Master / Backup | ens35 | wan_2 | vsw_isp2 |
| Ubuntu Router Master / Backup | ens36 | lan_trunk | vsw_lima |
| Ubuntu ISP2 | ens34 | wan_1 | vSwitch0 |
| Ubuntu ISP2 | ens35 | wan_2 | vsw_isp2 |
