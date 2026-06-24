# Playbook: Mail Server (iRedMail)

Instala y configura iRedMail en Ubuntu como servidor de correo completo con MySQL, Postfix, Dovecot, Roundcube, Fail2ban y Netdata.

## Hosts target

- Grupo: `ubuntu_mail`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `hostname_mail` | vars del play | Hostname corto (mail) |
| `domain_mail` | vars del play | Dominio de correo (norcom.internal) |
| `mail_ip` | vars del play | IP del servidor (192.168.10.9) |
| `dns_master_ip` | vars del play | DNS primario (192.168.10.5) |
| `dns_secondary_ip` | vars del play | DNS secundario (192.168.10.6) |
| `iredmail_version` | vars del play | Versión iRedMail (1.7.2) |
| `iredmail_admin_password` | group_vars/all/vault.yml | Password admin (MySQL+webmail) |

## Funcionalidades

- Descarga automática de iRedMail desde GitHub
- Instalación no interactiva con archivo de respuestas
- Configuración de DNS local (systemd-resolved)
- Configuración de hostname como FQDN
- Firewall UFW con reglas para todos los servicios de correo
- Instalación protegida: UFW se deshabilita solo durante la descarga y se rehabilita automáticamente

## Dependencias

- Paquetes base: wget, curl, ufw
- Conexión a Internet para descargar iRedMail
- DNS apuntando al dominio de correo

## Orden de ejecución

- Independiente (no requiere AD ni otros servicios)
- Debe tener resolución DNS para `mail.norcom.internal`

## Uso

```bash
ansible-playbook playbooks/services/mail_server.yml
```

## Notas

- La instalación toma ~30 minutos
- iRedMail instala MySQL, Postfix, Dovecot, Roundcube, Fail2ban y Netdata automáticamente
- La contraseña configurada en `iredmail_admin_password` se usa para MySQL root, vmail, iRedAdmin y Roundcube
