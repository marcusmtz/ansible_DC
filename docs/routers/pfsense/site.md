# Playbook: pfSense Router (unificado)

Configuración completa de routers pfSense en alta disponibilidad CARP: sistema básico, VLANs, VIPs, NAT outbound, firewall, DHCP relay, pfsync y XMLRPC sync.

## Hosts target

- Grupo: `pfsense_routers`
- Los nodos se diferencian por `is_master` (bool) para condicionar XMLRPC HA sync (solo master empuja al backup)

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `hostname` | group_vars/pfsense_router_master/backup | Hostname del router |
| `pfsense_host` | group_vars/pfsense_routers | IP de gestión |
| `pfsense_username` | group_vars/pfsense_routers | Usuario admin |
| `pfsense_password` | group_vars/pfsense_routers/vault.yml | Password admin |
| `wan1_address`, `wan2_address` | group_vars/pfsense_router_master/backup | IPs WAN |
| `wan1_subnet`, `wan2_subnet` | group_vars/pfsense_router_master/backup | Máscaras WAN |
| `wan1_gateway`, `wan2_gateway` | group_vars/pfsense_router_master/backup | Gateways ISP |
| `wan1_interface`, `wan2_interface` | group_vars/pfsense_routers | Interfaces físicas |
| `wan1_gateway_name`, `wan2_gateway_name` | group_vars/pfsense_routers | Nombres gateway |
| `vlans` | group_vars/pfsense_routers | Lista de VLANs con ipaddr, subnet, vip, vhid, advskew |
| `trunk_interface` | group_vars/pfsense_routers | Interfaz trunk |
| `domain`, `timezone`, `dns_servers` | group_vars/all | Config global |
| `carp_password` | group_vars/pfsense_routers/vault.yml | Password CARP |
| `carp_role` | group_vars/pfsense_router_master/backup | master/backup |
| `ha_sync_peer` | group_vars/pfsense_router_master/backup | IP del peer HA |
| `dhcp_relay_server` | group_vars/pfsense_routers | IP servidor DHCP |
| `is_master` | group_vars/pfsense_router_master/backup | Bool para XMLRPC condicional |

## Dependencias

- Colección: `pfsensible.core` (instalar con `ansible-galaxy collection install pfsensible.core`)
- Variables de `group_vars/all/vault.yml` si hay credenciales compartidas

## Orden de ejecución

1. `playbooks/routers/pfsense/site.yml` — configuración completa del router
2. `playbooks/routers/pfsense/allow_servidores_internet.yml` — (opcional) regla extra de firewall

## Uso

```bash
ansible-playbook playbooks/routers/pfsense/site.yml
```
