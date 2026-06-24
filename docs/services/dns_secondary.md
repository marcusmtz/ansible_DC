# Playbook: DNS Secundario (BIND9)

Configura un servidor DNS secundario con BIND9 que replica las zonas del DNS primario (DC1). Incluye forwarders, ACLs de recurisión y reglas de firewall UFW.

## Hosts target

- Grupo: `ubuntu_dns_secondary`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `dns_listen_ip` | vars del play | IP de escucha (192.168.10.6) |
| `dns_master_ip` | vars del play | IP del DNS primario (192.168.10.5) |
| `dns_zones` | vars del play | Lista de zonas a replicar |

## Dependencias

- Paquetes: bind9, bind9-utils, dnsutils
- El DNS primario (DC1) debe permitir transferencias de zona a esta IP

## Orden de ejecución

- Después de configurar el DC primario (playbooks/windows/promote_dc.yml + post_dc.yml)
- El DC primario debe tener configurada la transferencia de zona al secundario (se hace en post_dc.yml)

## Uso

```bash
ansible-playbook playbooks/services/dns_secondary.yml
```
