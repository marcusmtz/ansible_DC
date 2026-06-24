# Playbook: Windows — Site (wrapper)

Playbook contenedor que importa y ejecuta los dos playbooks de Windows en orden:
1. `promote_dc.yml` — crea el dominio AD
2. `post_dc.yml` — configura DHCP y DNS

## Hosts target

- `windows_local` → `promote_dc.yml` (usa credenciales locales .\Administrador)
- `windows_domain` → `post_dc.yml` (usa credenciales de dominio NORCOM\Administrador)

## Variables

Ver docs individuales de cada playbook.

## Dependencias

- Colección: `microsoft.ad` (para promote_dc.yml)
- Credenciales en `group_vars/windows/vault.yml`

## Orden de ejecución

- Único comando para configurar el DC completo

## Uso

```bash
ansible-playbook playbooks/windows/site.yml
```

Equivalente a ejecutar:
```bash
ansible-playbook playbooks/windows/promote_dc.yml
ansible-playbook playbooks/windows/post_dc.yml
```
