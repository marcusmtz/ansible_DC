# Playbook: Promover Domain Controller

Instala Active Directory Domain Services y DNS, crea un nuevo bosque `norcom.internal`, habilita RDP y configura reglas de firewall.

## Hosts target

- Grupo: `windows_local` (conexión con usuario local `.\Administrador`)
- Contraseña desde `group_vars/windows/vault.yml`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `domain_name` | vars del play | Nombre del dominio (norcom.internal) |
| `netbios_name` | vars del play | Nombre NetBIOS (NORCOM) |
| `dsrm_password` | group_vars/windows/vault.yml | Password modo restauración DSRM |

## Requisitos previos del host

- Windows Server con WinRM configurado y accesible
- IP estática configurada manualmente
- Ejecutar `scripts/windows/Configurar-PreAnsible.ps1` en el servidor antes del playbook

## Dependencias

- Colección: `microsoft.ad`
- Credenciales: `group_vars/windows/vault.yml`

## Orden de ejecución

1. `promote_dc.yml` — crear dominio (se ejecuta como usuario local)
2. `post_dc.yml` — configurar DHCP y DNS (se ejecuta como usuario de dominio)

## Uso

```bash
ansible-playbook playbooks/windows/promote_dc.yml
```
