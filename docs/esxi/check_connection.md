# Playbook: ESXi — Check Connection

Prueba de conectividad con un host ESXi. Obtiene y muestra la versión, build y hostname del servidor ESXi.

## Hosts target

- Grupo: `esxi_hosts`
- Conexión: `local` (ansible_connection=local)

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `esxi_host` | group_vars/esxi_hosts | IP/hostname del ESXi |
| `esxi_user` | group_vars/esxi_hosts | Usuario ESXi |
| `esxi_pass` | group_vars/esxi_hosts/vault.yml | Password ESXi |
| `validate_certs` | group_vars/esxi_hosts | false |

## Dependencias

- Colección: `community.vmware`

## Orden de ejecución

- Útil como prueba de conectividad antes de ejecutar otros playbooks ESXi

## Uso

```bash
ansible-playbook playbooks/esxi/check_connection.yml
```
