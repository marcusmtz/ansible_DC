# Playbook: Post-Dominio (DHCP + DNS)

Configura el servidor DHCP con 3 scopes (Administración, TI, Ventas), autoriza el servidor en AD y configura el DNS primario para permitir transferencias al secundario.

## Hosts target

- Grupo: `windows_domain` (conexión con usuario de dominio `NORCOM\Administrador`)
- Contraseña desde `group_vars/windows/vault.yml`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `dhcp_scopes` | vars del play | Lista de scopes DHCP con rangos y opciones |

### Scopes creados

| Scope | Red | Rango | Gateway |
|---|---|---|---|
| VLAN20-Administracion | 192.168.20.0/25 | .50 -.120 | 192.168.20.1 |
| VLAN30-TI | 192.168.30.0/26 | .30 -.60 | 192.168.30.1 |
| VLAN40-Ventas | 192.168.40.0/25 | .50 -.120 | 192.168.40.1 |

## Dependencias

- El dominio AD debe existir (ejecutar `promote_dc.yml` primero)
- Colección: ninguna adicional (usa win_shell)

## Orden de ejecución

1. `promote_dc.yml` — crear dominio
2. `post_dc.yml` — DHCP y DNS

## Uso

```bash
ansible-playbook playbooks/windows/post_dc.yml
```
