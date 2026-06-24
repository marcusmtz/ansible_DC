# Playbook: Allow Servidores a Internet

Agrega una regla de firewall en pfSense para permitir tráfico saliente a Internet desde la VLAN Servidores, excluyendo redes RFC1918.

## Hosts target

- Grupo: `pfsense_routers` (se ejecuta en master y backup)

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `pfsense_host` | group_vars/pfsense_routers | IP de gestión |
| `pfsense_username` | group_vars/pfsense_routers | Usuario admin |
| `pfsense_password` | group_vars/pfsense_routers/vault.yml | Password admin |

## Dependencias

- Colección: `pfsensible.core`
- Debe ejecutarse después de `site.yml` (requiere VLANs ya creadas)

## Orden de ejecución

1. `playbooks/routers/pfsense/site.yml` — configuración base
2. `playbooks/routers/pfsense/allow_servidores_internet.yml` — regla adicional

## Uso

```bash
ansible-playbook playbooks/routers/pfsense/allow_servidores_internet.yml
```
