# Playbook: Ubuntu Router Backup

Configura el router Ubuntu de respaldo con balanceo ECMP multi-WAN, VRRP para alta disponibilidad de VLANs, políticas de tráfico y firewall. Es idéntico en funcionalidad a site_master pero con direcciones IP distintas para el nodo backup.

## Hosts target

- Grupo: `ubuntu_router_backup`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `wan_interface` | vars del play | Interfaz WAN1 (ens34) |
| `wan1_address`, `wan1_gateway` | vars del play | IP WAN1 (172.17.25.42/24) |
| `wan2_interface` | vars del play | Interfaz WAN2 (ens35) |
| `wan2_address`, `wan2_gateway` | vars del play | IP WAN2 (168.17.25.3/29) |
| `trunk_interface` | vars del play | Interfaz trunk LAN (ens36) |
| `vlans` | vars del play | Lista de VLANs con VRRP |
| `vrrp_interface` | vars del play | Interfaz para VRRP |

## Funcionalidades

- Mismas que site_master: ECMP, VRRP, netplan, tc, iptables, sysctl

## Dependencias

- Paquetes: keepalived, vlan, iperf3, iftop, tcpdump, bridge-utils

## Orden de ejecución

1. `site_master.yml` — primero el master
2. `site_backup.yml` — luego el backup

## Uso

```bash
ansible-playbook playbooks/routers/ubuntu/site_backup.yml
```
