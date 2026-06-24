# Playbook: File Server (Samba + AD)

Configura un servidor de archivos Samba integrado con Active Directory. Une el servidor al dominio, configura winbind para autenticación y crea recursos compartidos por departamento.

## Hosts target

- Grupo: `ubuntu_file_server`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `domain` | vars del play | Dominio (norcom.internal) |
| `domain_upper` | vars del play | NetBIOS (NORCOM) |
| `domain_admin` | vars del play | Usuario de dominio (Administrador) |
| `domain_admin_password` | group_vars/all/vault.yml | Password del admin de dominio |
| `smb_shares` | vars del play | Lista de recursos compartidos |

## Recursos compartidos creados

| Recurso | Ruta | Grupo |
|---|---|---|
| CompartidoAdmin | /srv/samba/admin | Administracion |
| CompartidoTI | /srv/samba/ti | TI |
| CompartidoVentas | /srv/samba/ventas | Ventas |

## Dependencias

- Paquetes: samba, winbind, libpam-winbind, libnss-winbind, krb5-user, realmd, sssd, adcli
- El dominio AD debe existir y ser accesible
- Los grupos AD (Administracion, TI, Ventas) deben existir (se crean en ad_users.yml)

## Orden de ejecución

1. `playbooks/windows/site.yml` — crear dominio AD
2. `playbooks/windows/ad_users.yml` — crear grupos AD
3. `playbooks/services/file_server.yml` — unir al dominio y configurar Samba

## Uso

```bash
ansible-playbook playbooks/services/file_server.yml
```
