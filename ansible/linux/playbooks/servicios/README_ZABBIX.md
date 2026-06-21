# Playbook: Post-Configuración Zabbix en AlmaLinux

## Descripción

Este playbook realiza la configuración post-instalación de un servidor Zabbix en AlmaLinux, estableciendo los parámetros de red, seguridad y zona horaria requeridos para la infraestructura NORCOM.

## Servidor

- **Hostname:** zabbix
- **IP Estática:** 192.168.10.10/26 (VLAN 10 - Servidores)
- **Gateway:** 192.168.10.1 (VRRP VIP)
- **DNS:** 192.168.10.5 (DC1), 192.168.10.6 (DNS2)
- **Zona Horaria:** America/Lima

## Tareas Implementadas

### 1. ✅ Configuración de IP Estática
- Utiliza `nmcli` (NetworkManager) para configurar interfaz de red
- Parámetros configurables:
  - Interfaz de red (por defecto: `eth0`)
  - IP estática con máscara VLSM /26
  - Gateway y servidores DNS
  - Dominio de búsqueda DNS

### 2. ✅ Cambio de Contraseña Root
- Actualiza contraseña del usuario `root` del sistema
- Usa `password_hash('sha512')` para encriptación segura
- Contraseña oculta en logs (`no_log: true`)

### 3. ✅ Ajuste de Zona Horaria
**Sistema:**
- Configura zona horaria usando `community.general.timezone`
- Reinicia servicio `chronyd` si hay cambios

**PHP:**
- Actualiza `date.timezone` en `/etc/php.ini`
- Actualiza `php_value[date.timezone]` en `/etc/php-fpm.d/zabbix.conf`
- Reinicia servicios `php-fpm` y `httpd` (o `nginx`)

### 4. ✅ Seguridad Web
- Proporciona instrucciones para cambiar contraseña de usuario `Admin` de Zabbix
- Crea script `/tmp/zabbix_change_admin_password.sh` para cambio desde BD
- Incluye recordatorio de configuración de firewall

## Variables Configurables

Todas las variables están definidas en la sección `vars` del playbook:

```yaml
# Red
network_interface: "eth0"
static_ip: "192.168.10.10"
netmask: "255.255.255.192"  # /26 VLSM
prefix: 26
gateway: "192.168.10.1"
dns_servers: ["192.168.10.5", "192.168.10.6"]
dns_search: "norcom.internal"

# Seguridad
root_password: "Zabbix_Root_2024!"  # ⚠️ CAMBIAR

# Zona Horaria
system_timezone: "America/Lima"

# PHP
php_ini_path: "/etc/php.ini"
php_fpm_zabbix_conf: "/etc/php-fpm.d/zabbix.conf"

# Servicios
web_server: "httpd"  # O "nginx"
php_fpm_service: "php-fpm"
```

## Uso

### Ejecución del Playbook

```bash
# Desde el directorio ansible/
ansible-playbook -i linux/inventory.ini \
  linux/playbooks/servicios/almalinux_zabbix_postconfig.yml
```

### Con Variables Personalizadas

```bash
ansible-playbook -i linux/inventory.ini \
  linux/playbooks/servicios/almalinux_zabbix_postconfig.yml \
  -e "root_password=MiPasswordSegura123!" \
  -e "system_timezone=America/Bogota"
```

### Modo Check (Dry-run)

```bash
ansible-playbook -i linux/inventory.ini \
  linux/playbooks/servicios/almalinux_zabbix_postconfig.yml \
  --check --diff
```

## Post-Ejecución

### 1. Cambiar Contraseña Admin de Zabbix

**Opción A - Interfaz Web:**
1. Acceder a: `http://192.168.10.10/zabbix`
2. Usuario: `Admin`, Password: `zabbix` (default)
3. Ir a: **Administration → Users → Admin**
4. Cambiar password en la pestaña **User**

**Opción B - Script de Base de Datos:**
```bash
ssh ansible@192.168.10.10
sudo /tmp/zabbix_change_admin_password.sh
```

### 2. Configurar Firewall

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=10050/tcp  # Zabbix Agent
firewall-cmd --permanent --add-port=10051/tcp  # Zabbix Server
firewall-cmd --reload
```

### 3. Verificar Configuración

```bash
# Verificar IP configurada
ip addr show eth0

# Verificar zona horaria
timedatectl

# Verificar PHP timezone
php -i | grep "date.timezone"
grep "date.timezone" /etc/php.ini
grep "date.timezone" /etc/php-fpm.d/zabbix.conf

# Verificar servicios
systemctl status zabbix-server
systemctl status httpd
systemctl status php-fpm
```

## Handlers Implementados

Los siguientes handlers reinician servicios solo si hay cambios:

- `Restart NetworkManager` - Reinicia red si cambia configuración
- `Restart php-fpm` - Reinicia PHP-FPM si cambia timezone
- `Restart web server` - Reinicia Apache/Nginx si cambia timezone
- `Restart chronyd` - Reinicia servicio de tiempo si cambia zona horaria

## Prerequisitos

### En el servidor Zabbix (AlmaLinux):

1. **Usuario Ansible:**
```bash
useradd ansible
echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
```

2. **Clave SSH:**
```bash
# Desde tu máquina de control Ansible
ssh-copy-id ansible@192.168.10.10
```

3. **Python 3:**
```bash
dnf install -y python3
```

### En la máquina de control:

```bash
# Instalar colecciones requeridas
ansible-galaxy collection install community.general
```

## Integración con VLAN 10 - Servidores

Este servidor forma parte de la VLAN 10 (Servidores) con VLSM /26:

| Servidor | IP | Propósito |
|----------|-----|-----------|
| Gateway VIP | 192.168.10.1 | VRRP Virtual IP |
| Router Master | 192.168.10.2 | Router principal |
| Router Backup | 192.168.10.3 | Router respaldo |
| DC1 | 192.168.10.5 | Domain Controller + DNS |
| DNS2 | 192.168.10.6 | DNS Secundario |
| FileServer | 192.168.10.7 | Samba File Server |
| MailServer | 192.168.10.9 | iRedMail |
| **Zabbix** | **192.168.10.10** | **Monitoring Server** |
| Disponibles | .11 - .62 | Futuros servidores |

## Políticas de Acceso

Según las políticas inter-VLAN de NORCOM:

✅ **Acceso PERMITIDO desde:**
- VLAN 20 (Administración) - Acceso completo
- VLAN 30 (TI) - Acceso completo para monitoreo
- VLAN 40 (Ventas) - Solo consulta web

✅ **Zabbix puede monitorear:**
- Todos los hosts en VLAN 10 (Servidores)
- Hosts en otras VLANs si tienen agente Zabbix instalado

## Troubleshooting

### IP no se aplica
```bash
# Verificar NetworkManager
systemctl status NetworkManager

# Ver conexiones activas
nmcli connection show

# Reactivar conexión
nmcli connection up eth0
```

### PHP timezone no cambia
```bash
# Verificar sintaxis PHP
php -l /etc/php.ini

# Verificar permisos
ls -l /etc/php.ini /etc/php-fpm.d/zabbix.conf

# Reiniciar servicios manualmente
systemctl restart php-fpm httpd
```

### No se puede cambiar contraseña Admin
```bash
# Verificar base de datos
mysql -u zabbix -p
> USE zabbix;
> SELECT userid, username FROM users WHERE username='Admin';
> QUIT;

# Ejecutar script con debug
bash -x /tmp/zabbix_change_admin_password.sh
```

## Seguridad

⚠️ **Importante:**
- Cambiar `root_password` antes de ejecutar en producción
- Usar Ansible Vault para contraseñas sensibles:
  ```bash
  ansible-vault encrypt_string 'MiPasswordSegura' --name 'root_password'
  ```
- Deshabilitar acceso SSH con password después de configurar:
  ```bash
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  systemctl restart sshd
  ```

## Referencias

- [Documentación Zabbix](https://www.zabbix.com/documentation)
- [AlmaLinux Network Configuration](https://wiki.almalinux.org/documentation/networking.html)
- [Ansible nmcli module](https://docs.ansible.com/ansible/latest/collections/community/general/nmcli_module.html)
