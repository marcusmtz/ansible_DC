# Playbooks de Windows - Active Directory Domain Controller

## 📋 Contenido

Este directorio contiene los playbooks de Ansible para configurar un Domain Controller de Windows Server con Active Directory, DNS y DHCP.

## 🎯 Arquitectura

```
┌─────────────────────────────────────────┐
│   Domain Controller (DC01)              │
│   IP: 192.168.10.5                      │
│   VLAN: 10 (Servidores)                 │
│                                         │
│   Servicios:                            │
│   • Active Directory Domain Services    │
│   • DNS Primary (norcom.internal)       │
│   • DHCP Server (3 scopes)             │
└─────────────────────────────────────────┘
```

## 📚 Playbooks Disponibles

### 1. `promote_dc.yml` - Promoción a Domain Controller
**Host:** `windows_local` (credenciales locales)

**Acciones:**
- ✅ Instala AD DS y DNS
- ✅ Habilita Remote Desktop (RDP)
- ✅ Crea bosque `norcom.internal`
- ✅ NetBIOS: `NORCOM`
- ✅ Reinicia el servidor

---

### 2. `post_dc.yml` - Configuración Post-Promoción
**Host:** `windows_domain` (credenciales de dominio)

**Acciones:**
- ✅ Instala servicio DHCP
- ✅ Crea 3 scopes DHCP
- ✅ Configura DNS secundario

---

### 3. `windows_ad_dhcp.yml` - Playbook Completo ⭐
**Recomendado:** Ejecuta promote_dc + post_dc automáticamente

---

### 4. `ad_users.yml` - Usuarios y Grupos
**Acciones:**
- ✅ Crea grupos: Administracion, TI, Ventas
- ✅ Crea 6 usuarios

---

## 🚀 Ejecución Rápida

```bash
# TODO en un comando
ansible-playbook -i ../inventory.ini windows_ad_dhcp.yml

# Luego crear usuarios
ansible-playbook -i ../inventory.ini ad_users.yml
```

## 📖 Documentación Completa

Lee la documentación completa en:
- `../PREPARACION_WINDOWS_SERVER.md` - Configuración previa del servidor
- `../Configurar-PreAnsible.ps1` - Script de configuración automática

---

**Versión:** 1.0
