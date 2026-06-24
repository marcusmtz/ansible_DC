# Playbook: Ubuntu Router Master

Configura el router Ubuntu principal con balanceo ECMP multi-WAN, VRRP para alta disponibilidad de VLANs, políticas de tráfico con tc y reglas de firewall con iptables.

## Hosts target

- Grupo: `ubuntu_router_master`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `wan_interface` | vars del play | Interfaz WAN1 (ens34) |
| `wan1_address`, `wan1_gateway` | vars del play | IP WAN1 (172.17.25.90/24) |
| `wan2_interface` | vars del play | Interfaz WAN2 (ens35) |
| `wan2_address`, `wan2_gateway` | vars del play | IP WAN2 (168.17.25.2/29) |
| `trunk_interface` | vars del play | Interfaz trunk LAN (ens36) |
| `vlans` | vars del play | Lista de VLANs con VRRP |
| `vrrp_interface` | vars del play | Interfaz para VRRP |

## Funcionalidades

- **ECMP**: Balanceo de carga entre WAN1 y WAN2 con rutas por igual costo
- **VRRP**: VIP por VLAN (VLAN 10-40) con Keepalived
- **Netplan**: Configuración de interfaces, VLANs y bridging
- **tc (traffic control)**: Clasificación de tráfico por VLAN con prioridades
- **iptables**: NAT MASQUERADE, forwarding segmentado por VLAN
- **sysctl**: IP forwarding, reverse path filtering, optimización de red

## Dependencias

- Paquetes: keepalived, vlan, iperf3, iftop, tcpdump, bridge-utils

## Orden de ejecución

1. `site_master.yml` — configurar router master
2. `site_backup.yml` — configurar router backup (debe tener IPs e interfaces distintas)

## Uso

```bash
ansible-playbook playbooks/routers/ubuntu/site_master.yml
```
