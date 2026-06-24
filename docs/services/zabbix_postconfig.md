# Playbook: Zabbix Post-Configuración

Configura un servidor Zabbix en AlmaLinux después de la instalación base: IP estática, contraseña de root, zona horaria (sistema + PHP) y genera script para cambio de contraseña del usuario Admin.

## Hosts target

- Grupo: `zabbix_server`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `network_interface` | vars del play | Interfaz de red (eth0) |
| `static_ip` | vars del play | IP estática (192.168.10.10) |
| `netmask` | vars del play | Máscara /26 |
| `prefix` | vars del play | Prefijo (26) |
| `gateway` | vars del play | Gateway (192.168.10.1) |
| `dns_servers` | vars del play | DNS servers |
| `dns_search` | vars del play | Dominio de búsqueda |
| `root_password` | group_vars/all/vault.yml | Password root |
| `system_timezone` | vars del play | Zona horaria (America/Lima) |

## Dependencias

- Colección: `community.general` (nmcli, timezone)
- Paquetes: NetworkManager
- Zabbix debe estar previamente instalado (no incluido en este playbook)

## Orden de ejecución

- Ejecutar después de instalar Zabbix manualmente o con otro playbook
- Configura solo IP, contraseña root y timezone

## Uso

```bash
ansible-playbook playbooks/services/zabbix_postconfig.yml
```

## Notas

- El cambio de contraseña root se aplica solo la primera vez (update_password: on_create)
- El script `/tmp/zabbix_change_admin_password.sh` es interactivo y debe ejecutarse manualmente en el servidor
- Las reglas de firewall (firewall-cmd) no se aplican automáticamente, solo se muestran como recordatorio
