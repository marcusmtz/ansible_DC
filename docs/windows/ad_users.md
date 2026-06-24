# Playbook: Usuarios y Grupos AD

Crea grupos de seguridad (Administracion, TI, Ventas) y usuarios de prueba en Active Directory.

## Hosts target

- Grupo: `windows_domain` (usuario de dominio)

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `ad_groups` | vars del play | Lista de grupos: Administracion, TI, Ventas |
| `ad_users` | vars del play | Lista de 6 usuarios con nombre, grupo y contraseña |

### Usuarios creados

| Usuario | Grupo | Contraseña |
|---|---|---|
| admin1, admin2 | Administracion | Admin1!, Admin2! |
| ti1, ti2 | TI | TI1!, TI2! |
| ventas1, ventas2 | Ventas | Ventas1!, Ventas2! |

## Dependencias

- El dominio AD debe existir
- La promoción del DC debe estar completa (promote_dc.yml + reinicio)
- Colección: `microsoft.ad`

## Orden de ejecución

1. `promote_dc.yml` — crear dominio
2. `post_dc.yml` — DHCP y DNS
3. `ad_users.yml` — usuarios y grupos (opcional, para pruebas)

## Uso

```bash
ansible-playbook playbooks/windows/ad_users.yml
```

## Notas

- Las contraseñas de los usuarios demo están en texto plano en el playbook (usuarios de prueba/documentación)
- `update_password: on_create` evita sobrescribir si se cambian manualmente después
