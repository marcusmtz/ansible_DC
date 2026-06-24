# Tasks: ESXi — Mount ISO (include_tasks)

**Nota:** Este no es un playbook independiente, es un archivo de tareas (tasks) que se incluye mediante `include_tasks` desde `create_gamecenter_vms.yml`.

Monta una ISO en una VM de ESXi, primero intentando con controladora IDE y haciendo fallback a SATA si falla.

## Incluido por

- `playbooks/esxi/create_gamecenter_vms.yml` (línea 118: `include_tasks: mount_iso.yml`)

## Variables de contexto

| Variable | Origen | Descripción |
|---|---|---|
| `item` | loop de create_gamecenter_vms | Objeto VM con .name e .iso_file |

## Comportamiento

1. Intenta montar la ISO con `controller_type: ide`, `unit_number: 0`
2. Si falla, rescata con `controller_type: sata`, `unit_number: 0`

## Dependencias

- Colección: `community.vmware`
- Variables del playbook padre: `esxi_host`, `esxi_user`, `esxi_pass`, `esxi_hostname_fqdn`, `ds_name`, `iso_folder`

## Uso

No se ejecuta directamente. Se invoca automáticamente desde `create_gamecenter_vms.yml`.
