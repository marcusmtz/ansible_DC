# Preparación de Windows Server para Ansible - Domain Controller

## 📋 Tabla de Contenidos

1. [Configuración de Red Estática](#configuración-de-red-estática)
2. [Habilitar WinRM para Ansible](#habilitar-winrm-para-ansible)
3. [Configuración de Firewall](#configuración-de-firewall)
4. [Cambiar Nombre del Servidor](#cambiar-nombre-del-servidor-opcional)
5. [Verificación Completa](#verificación-completa)
6. [Troubleshooting](#troubleshooting)

---

## 🖥️ Configuración de Red Estática

### Información de Red para el Domain Controller

```
IP Address:           192.168.10.5
Subnet Mask:          255.255.255.192  (/26)
Default Gateway:      192.168.10.1
Preferred DNS:        8.8.8.8          (temporal, cambiará después de ser DC)
Alternate DNS:        192.168.10.6     (DNS secundario - BIND9)
VLAN:                 10 (Servidores)
```

### Método 1: Configuración via GUI

**Pasos:**

1. Abre el **Panel de Control**
2. Ve a **Network and Sharing Center**
3. Click en **Change adapter settings** (lado izquierdo)
4. Click derecho en tu adaptador de red (usualmente "Ethernet" o "Ethernet0")
5. Selecciona **Properties**
6. Doble click en **Internet Protocol Version 4 (TCP/IPv4)**

**Configuración:**

```
☑️ Use the following IP address:

   IP address:         192.168.10.5
   Subnet mask:        255.255.255.192
   Default gateway:    192.168.10.1

☑️ Use the following DNS server addresses:

   Preferred DNS server:   8.8.8.8
   Alternate DNS server:   192.168.10.6

[✓] Validate settings upon exit
```

7. Click **OK** → **OK** → **Close**

### Método 2: Configuración via PowerShell (Recomendado)

**Ejecutar PowerShell como Administrador:**

```powershell
# 1. Ver adaptadores de red disponibles
Get-NetAdapter

# Salida esperada:
# Name                      InterfaceDescription                    ifIndex Status
# ----                      --------------------                    ------- ------
# Ethernet0                 Intel(R) 82574L Gigabit Network...          6 Up

# 2. Configurar IP estática (reemplaza "Ethernet0" con tu adaptador)
$AdapterName = "Ethernet0"

New-NetIPAddress `
  -InterfaceAlias $AdapterName `
  -IPAddress 192.168.10.5 `
  -PrefixLength 26 `
  -DefaultGateway 192.168.10.1

# 3. Configurar servidores DNS
Set-DnsClientServerAddress `
  -InterfaceAlias $AdapterName `
  -ServerAddresses ("8.8.8.8", "192.168.10.6")

# 4. Verificar configuración
Get-NetIPAddress -InterfaceAlias $AdapterName | Format-Table
Get-DnsClientServerAddress -InterfaceAlias $AdapterName
```

**Verificar conectividad:**

```powershell
# Probar gateway
ping 192.168.10.1

# Probar Internet
ping 8.8.8.8

# Probar resolución DNS
nslookup google.com
```

---

## 🔧 Habilitar WinRM para Ansible

### ¿Qué es WinRM?

**Windows Remote Management (WinRM)** es el protocolo que Ansible usa para conectarse y administrar servidores Windows de forma remota.

### Configuración Completa de WinRM

**Ejecutar en PowerShell como Administrador:**

```powershell
# 1. Habilitar PowerShell Remoting
Enable-PSRemoting -Force

# 2. Configurar WinRM con configuración rápida
winrm quickconfig -quiet

# 3. Configurar autenticación básica (requerido por Ansible)
winrm set winrm/config/service/auth '@{Basic="true"}'

# 4. Permitir tráfico sin cifrar (solo para redes privadas seguras)
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# 5. Aumentar límites de memoria para comandos grandes
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config/winrs '@{MaxShellsPerUser="50"}'

# 6. Configurar listeners HTTP
winrm create winrm/config/Listener?Address=*+Transport=HTTP

# 7. Verificar configuración
winrm get winrm/config
```

### Configuración de Listener HTTP Específico

```powershell
# Ver listeners actuales
winrm enumerate winrm/config/listener

# Si necesitas crear uno específicamente:
winrm create winrm/config/Listener?Address=*+Transport=HTTP '@{Port="5985"}'
```

### Verificar que WinRM está funcionando

```powershell
# Test local
Test-WSMan -ComputerName localhost

# Salida esperada:
# wsmid           : http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd
# ProtocolVersion : http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd
# ProductVendor   : Microsoft Corporation
# ProductVersion  : OS: 10.0.17763 SP: 0.0 Stack: 3.0

# Ver el servicio WinRM
Get-Service WinRM

# Debe mostrar:
# Status   Name               DisplayName
# ------   ----               -----------
# Running  WinRM              Windows Remote Management (WS-Manag...
```

---

## 🔥 Configuración de Firewall

### Reglas de Firewall para WinRM y RDP

```powershell
# 1. Habilitar regla para WinRM HTTP (puerto 5985)
netsh advfirewall firewall add rule `
  name="WinRM-HTTP" `
  dir=in `
  localport=5985 `
  protocol=TCP `
  action=allow `
  profile=any

# 2. Habilitar Remote Desktop (RDP) - Puerto 3389
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
  -Name "fDenyTSConnections" `
  -Value 0

# 3. Habilitar reglas de firewall para RDP
Enable-NetFirewallRule -Name "RemoteDesktop*"

# O manualmente:
netsh advfirewall firewall add rule `
  name="Remote Desktop - User Mode (TCP-In)" `
  dir=in `
  localport=3389 `
  protocol=TCP `
  action=allow `
  profile=any

# 4. Verificar reglas de firewall
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*WinRM*" -or $_.DisplayName -like "*Remote Desktop*"} | Select-Object DisplayName, Enabled, Direction
```

### Verificar Puertos Abiertos

```powershell
# Ver puertos en escucha
netstat -ano | findstr :5985
netstat -ano | findstr :3389

# Salida esperada para WinRM:
#   TCP    0.0.0.0:5985           0.0.0.0:0              LISTENING       <PID>
#   TCP    [::]:5985              [::]:0                 LISTENING       <PID>
```

---

## 🏷️ Cambiar Nombre del Servidor (Opcional)

### ¿Por qué cambiar el nombre?

- **Identificación clara** en Active Directory
- **Mejor organización** en la red
- **Recomendado** antes de promover a Domain Controller

### Cambiar a "DC01"

```powershell
# Ver nombre actual
$env:COMPUTERNAME

# Cambiar nombre y reiniciar
Rename-Computer -NewName "DC01" -Restart -Force
```

**El servidor se reiniciará automáticamente.**

### Verificar después del reinicio

```powershell
# Verificar nuevo nombre
$env:COMPUTERNAME
# Debe mostrar: DC01

hostname
# Debe mostrar: DC01
```

---

## ✅ Verificación Completa

### Script de Verificación Completo

Guarda esto como `Verificar-Configuracion.ps1` y ejecútalo:

```powershell
# ============================================
# Script de Verificación Pre-Ansible
# ============================================

Write-Host "`n=== VERIFICACION DE CONFIGURACION ===" -ForegroundColor Cyan

# 1. Verificar IP
Write-Host "`n[1] Configuración de Red:" -ForegroundColor Yellow
$ipConfig = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -eq "192.168.10.5"}
if ($ipConfig) {
    Write-Host "  ✓ IP configurada correctamente: 192.168.10.5" -ForegroundColor Green
} else {
    Write-Host "  ✗ IP NO está configurada correctamente" -ForegroundColor Red
}

# 2. Verificar Gateway
Write-Host "`n[2] Gateway:" -ForegroundColor Yellow
$gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty NextHop
if ($gateway -eq "192.168.10.1") {
    Write-Host "  ✓ Gateway configurado: $gateway" -ForegroundColor Green
} else {
    Write-Host "  ✗ Gateway incorrecto: $gateway" -ForegroundColor Red
}

# 3. Verificar DNS
Write-Host "`n[3] Servidores DNS:" -ForegroundColor Yellow
$dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses -ne $null}
Write-Host "  DNS configurados: $($dnsServers.ServerAddresses -join ', ')"

# 4. Verificar conectividad
Write-Host "`n[4] Pruebas de Conectividad:" -ForegroundColor Yellow

$tests = @(
    @{Name="Gateway"; IP="192.168.10.1"},
    @{Name="Internet"; IP="8.8.8.8"}
)

foreach ($test in $tests) {
    $result = Test-Connection -ComputerName $test.IP -Count 1 -Quiet
    if ($result) {
        Write-Host "  ✓ $($test.Name) ($($test.IP)): Accesible" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($test.Name) ($($test.IP)): NO accesible" -ForegroundColor Red
    }
}

# 5. Verificar WinRM
Write-Host "`n[5] Servicio WinRM:" -ForegroundColor Yellow
$winrm = Get-Service WinRM
if ($winrm.Status -eq "Running") {
    Write-Host "  ✓ WinRM está en ejecución" -ForegroundColor Green
    
    # Test WinRM
    try {
        $test = Test-WSMan -ComputerName localhost -ErrorAction Stop
        Write-Host "  ✓ WinRM responde correctamente" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ WinRM no responde: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ WinRM NO está en ejecución" -ForegroundColor Red
}

# 6. Verificar puerto WinRM
Write-Host "`n[6] Puerto WinRM (5985):" -ForegroundColor Yellow
$listener = netstat -ano | Select-String ":5985" | Select-String "LISTENING"
if ($listener) {
    Write-Host "  ✓ Puerto 5985 está en escucha" -ForegroundColor Green
} else {
    Write-Host "  ✗ Puerto 5985 NO está en escucha" -ForegroundColor Red
}

# 7. Verificar firewall WinRM
Write-Host "`n[7] Reglas de Firewall:" -ForegroundColor Yellow
$fwRule = Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*WinRM*" -and $_.Enabled -eq $true}
if ($fwRule) {
    Write-Host "  ✓ Reglas de firewall WinRM habilitadas" -ForegroundColor Green
} else {
    Write-Host "  ✗ Reglas de firewall WinRM NO encontradas" -ForegroundColor Red
}

# 8. Verificar RDP
Write-Host "`n[8] Remote Desktop (RDP):" -ForegroundColor Yellow
$rdpEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections").fDenyTSConnections
if ($rdpEnabled -eq 0) {
    Write-Host "  ✓ RDP está habilitado" -ForegroundColor Green
} else {
    Write-Host "  ✗ RDP está deshabilitado" -ForegroundColor Red
}

# 9. Verificar nombre del servidor
Write-Host "`n[9] Información del Servidor:" -ForegroundColor Yellow
Write-Host "  Nombre: $env:COMPUTERNAME"
Write-Host "  Dominio/Workgroup: $((Get-WmiObject Win32_ComputerSystem).Domain)"

# Resumen final
Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Si todos los checks tienen ✓, el servidor está listo para Ansible" -ForegroundColor Green
Write-Host "`nPróximo paso: Ejecutar el playbook de Ansible" -ForegroundColor Yellow
Write-Host "  ansible-playbook -i windows/inventory.ini windows/playbooks/windows_ad_dhcp.yml`n" -ForegroundColor White
```

### Ejecutar el script de verificación

```powershell
# Guardar el script y ejecutar
.\Verificar-Configuracion.ps1

# O copiar y pegar directamente en PowerShell
```

**Salida esperada con ✓ en todos los checks.**

---

## 🔍 Troubleshooting

### Problema: WinRM no inicia

```powershell
# Reiniciar servicio WinRM
Restart-Service WinRM -Force

# Verificar estado
Get-Service WinRM

# Ver logs de eventos
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 20 | Where-Object {$_.Message -like "*WinRM*"}
```

### Problema: Ansible no puede conectar

```powershell
# Verificar configuración WinRM completa
winrm get winrm/config

# Verificar listeners
winrm enumerate winrm/config/listener

# Verificar autenticación básica
winrm get winrm/config/service/auth

# Debe mostrar:
# Basic = true
```

### Problema: Firewall bloquea conexiones

```powershell
# Desactivar firewall temporalmente para probar (solo testing)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Si funciona, el problema es el firewall. Reactiva y configura reglas:
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Agregar regla manualmente
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow
```

### Problema: No hay conectividad de red

```powershell
# Verificar tabla de rutas
route print

# Verificar gateway por defecto
Get-NetRoute -DestinationPrefix "0.0.0.0/0"

# Probar conectividad
Test-NetConnection -ComputerName 192.168.10.1 -Port 80
```

### Problema: DNS no resuelve

```powershell
# Limpiar cache DNS
ipconfig /flushdns

# Probar resolución
nslookup google.com
nslookup google.com 8.8.8.8

# Registrar DNS del servidor
ipconfig /registerdns
```

---

## 📝 Checklist Final

Antes de ejecutar Ansible, verifica:

- [ ] ✅ IP estática configurada: **192.168.10.5/26**
- [ ] ✅ Gateway configurado: **192.168.10.1**
- [ ] ✅ DNS configurado: **8.8.8.8, 192.168.10.6**
- [ ] ✅ Ping al gateway funciona
- [ ] ✅ Ping a Internet funciona (8.8.8.8)
- [ ] ✅ WinRM está en ejecución
- [ ] ✅ Puerto 5985 está en escucha
- [ ] ✅ Autenticación básica WinRM habilitada
- [ ] ✅ Firewall permite WinRM (puerto 5985)
- [ ] ✅ RDP habilitado (opcional pero recomendado)
- [ ] ✅ Nombre del servidor cambiado a DC01 (opcional)
- [ ] ✅ Script de verificación ejecutado con éxito

---

## 🚀 Siguiente Paso

Una vez completada toda la configuración, procede a ejecutar el playbook de Ansible:

```bash
# Desde tu servidor de Ansible (Ubuntu)
cd /ruta/a/ansible_DC

# Ejecutar playbook completo (DC + DHCP)
ansible-playbook -i ansible/windows/inventory.ini \
  ansible/windows/playbooks/windows_ad_dhcp.yml
```

---

## 📚 Referencias

- [Microsoft Docs - WinRM Configuration](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)
- [Ansible Windows Remote Management](https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html)
- [Windows Server Networking](https://docs.microsoft.com/en-us/windows-server/networking/)

---

**Documento creado por:** Ansible Automation  
**Fecha:** 2026-06-21  
**Versión:** 1.0
