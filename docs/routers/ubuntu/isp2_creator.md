# Playbook: ISP2 Creator (NAT Router)

Configura un Ubuntu Server como router NAT con netplan, iptables y forwarding. Crea una subred LAN detrás de la interfaz WAN con MASQUERADE.

## Hosts target

- Grupo: `isp2_creator`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `wan_interface` | vars del play | Interfaz WAN (ens34) |
| `lan_interface` | vars del play | Interfaz LAN (ens35) |
| `lan_address` | vars del play | IP LAN (168.17.25.1/29) |
| `nameservers` | vars del play | Lista de DNS |

## Dependencias

- Colección: `ansible.posix` (sysctl)
- Paquetes: iptables, iptables-persistent, netfilter-persistent

## Orden de ejecución

- Independiente. Se ejecuta cuando se necesita crear el router ISP2.

## Uso

```bash
ansible-playbook playbooks/routers/ubuntu/isp2_creator.yml
```
