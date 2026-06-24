# ============================================
# Script de Configuración Pre-Ansible
# Domain Controller - Windows Server
# ============================================
# Ejecutar como Administrador
# ============================================

# Verificar privilegios de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Debe ejecutar este script como Administrador" -ForegroundColor Red
    Write-Host "Click derecho en PowerShell → 'Ejecutar como Administrador'" -ForegroundColor Yellow
    exit 1
}

Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    CONFIGURACION PRE-ANSIBLE - WINDOWS SERVER DC          ║
║                                                           ║
║    Este script configurará:                               ║
║    • IP estática (192.168.10.5/26)                       ║
║    • WinRM para Ansible                                   ║
║    • Firewall (WinRM + RDP)                              ║
║    • Remote Desktop                                       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ============================================
# CONFIGURACION
# ============================================

$Config = @{
    IPAddress = "192.168.10.5"
    PrefixLength = 26
    Gateway = "192.168.10.1"
    DNS1 = "8.8.8.8"
    DNS2 = "192.168.10.6"
    NewComputerName = "DC01"  # Dejar en blanco para no cambiar
}

# ============================================
# 1. CONFIGURACION DE RED
# ============================================

Write-Host "`n[1/5] Configurando red estática..." -ForegroundColor Yellow

try {
    # Obtener adaptador activo
    $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    
    if (-not $adapter) {
        throw "No se encontró un adaptador de red activo"
    }
    
    Write-Host "  Adaptador detectado: $($adapter.Name)" -ForegroundColor Gray
    
    # Remover IP DHCP si existe
    $existingIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existingIP -and $existingIP.PrefixOrigin -eq "Dhcp") {
        Write-Host "  Removiendo configuración DHCP..." -ForegroundColor Gray
        Remove-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
    }
    
    # Configurar IP estática
    if ($existingIP.IPAddress -ne $Config.IPAddress) {
        Write-Host "  Configurando IP: $($Config.IPAddress)/$($Config.PrefixLength)" -ForegroundColor Gray
        New-NetIPAddress `
            -InterfaceAlias $adapter.Name `
            -IPAddress $Config.IPAddress `
            -PrefixLength $Config.PrefixLength `
            -DefaultGateway $Config.Gateway `
            -ErrorAction Stop | Out-Null
    } else {
        Write-Host "  IP ya configurada: $($Config.IPAddress)" -ForegroundColor Gray
    }
    
    # Configurar DNS
    Write-Host "  Configurando DNS: $($Config.DNS1), $($Config.DNS2)" -ForegroundColor Gray
    Set-DnsClientServerAddress `
        -InterfaceAlias $adapter.Name `
        -ServerAddresses ($Config.DNS1, $Config.DNS2) `
        -ErrorAction Stop
    
    Write-Host "  ✓ Red configurada correctamente" -ForegroundColor Green
    
    # Verificar conectividad
    Write-Host "  Probando conectividad al gateway..." -ForegroundColor Gray
    $pingResult = Test-Connection -ComputerName $Config.Gateway -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "  ✓ Gateway accesible ($($Config.Gateway))" -ForegroundColor Green
    } else {
        Write-Host "  ✗ ADVERTENCIA: Gateway no responde" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  ✗ Error configurando red: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# ============================================
# 2. HABILITAR WINRM
# ============================================

Write-Host "`n[2/5] Configurando WinRM para Ansible..." -ForegroundColor Yellow

try {
    # Habilitar PowerShell Remoting
    Write-Host "  Habilitando PowerShell Remoting..." -ForegroundColor Gray
    Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
    
    # Configuración rápida WinRM
    Write-Host "  Configurando WinRM..." -ForegroundColor Gray
    winrm quickconfig -quiet
    
    # Autenticación básica
    Write-Host "  Habilitando autenticación básica..." -ForegroundColor Gray
    winrm set winrm/config/service/auth '@{Basic="true"}' | Out-Null
    
    # Permitir tráfico sin cifrar (solo para redes privadas)
    Write-Host "  Configurando tráfico no cifrado..." -ForegroundColor Gray
    winrm set winrm/config/service '@{AllowUnencrypted="true"}' | Out-Null
    
    # Aumentar límites
    Write-Host "  Aumentando límites de memoria..." -ForegroundColor Gray
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' | Out-Null
    winrm set winrm/config/winrs '@{MaxShellsPerUser="50"}' | Out-Null
    
    # Iniciar servicio
    Write-Host "  Iniciando servicio WinRM..." -ForegroundColor Gray
    Start-Service WinRM -ErrorAction SilentlyContinue
    Set-Service WinRM -StartupType Automatic
    
    # Verificar
    $winrmService = Get-Service WinRM
    if ($winrmService.Status -eq "Running") {
        Write-Host "  ✓ WinRM configurado y en ejecución" -ForegroundColor Green
    } else {
        Write-Host "  ✗ WinRM no está en ejecución" -ForegroundColor Red
    }
    
    # Test WinRM
    $testResult = Test-WSMan -ComputerName localhost -ErrorAction SilentlyContinue
    if ($testResult) {
        Write-Host "  ✓ WinRM responde correctamente" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ✗ Error configurando WinRM: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# ============================================
# 3. CONFIGURAR FIREWALL
# ============================================

Write-Host "`n[3/5] Configurando firewall..." -ForegroundColor Yellow

try {
    # Regla WinRM HTTP
    Write-Host "  Creando regla para WinRM (puerto 5985)..." -ForegroundColor Gray
    $winrmRule = Get-NetFirewallRule -DisplayName "WinRM-HTTP" -ErrorAction SilentlyContinue
    if (-not $winrmRule) {
        New-NetFirewallRule `
            -DisplayName "WinRM-HTTP" `
            -Direction Inbound `
            -LocalPort 5985 `
            -Protocol TCP `
            -Action Allow `
            -Profile Any `
            -ErrorAction Stop | Out-Null
        Write-Host "  ✓ Regla WinRM creada" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Regla WinRM ya existe" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ✗ Error configurando firewall: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# ============================================
# 4. HABILITAR REMOTE DESKTOP (RDP)
# ============================================

Write-Host "`n[4/5] Habilitando Remote Desktop..." -ForegroundColor Yellow

try {
    # Habilitar RDP en el registro
    Write-Host "  Modificando registro..." -ForegroundColor Gray
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
        -Name "fDenyTSConnections" `
        -Value 0 `
        -ErrorAction Stop
    
    # Habilitar reglas de firewall para RDP
    Write-Host "  Habilitando reglas de firewall para RDP..." -ForegroundColor Gray
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    
    # Verificar
    $rdpEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
    if ($rdpEnabled -eq 0) {
        Write-Host "  ✓ Remote Desktop habilitado (puerto 3389)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ✗ Error habilitando RDP: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# ============================================
# 5. CAMBIAR NOMBRE DEL SERVIDOR (OPCIONAL)
# ============================================

if ($Config.NewComputerName -and $Config.NewComputerName -ne "") {
    Write-Host "`n[5/5] Cambiar nombre del servidor..." -ForegroundColor Yellow
    
    $currentName = $env:COMPUTERNAME
    if ($currentName -ne $Config.NewComputerName) {
        Write-Host "  Nombre actual: $currentName" -ForegroundColor Gray
        Write-Host "  Nombre nuevo: $($Config.NewComputerName)" -ForegroundColor Gray
        
        $response = Read-Host "  ¿Desea cambiar el nombre y reiniciar? (S/N)"
        if ($response -eq "S" -or $response -eq "s") {
            try {
                Rename-Computer -NewName $Config.NewComputerName -Force -ErrorAction Stop
                Write-Host "  ✓ Nombre cambiado. El servidor se reiniciará." -ForegroundColor Green
                $needsReboot = $true
            } catch {
                Write-Host "  ✗ Error cambiando nombre: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  → Cambio de nombre omitido" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✓ El nombre ya es: $currentName" -ForegroundColor Green
    }
} else {
    Write-Host "`n[5/5] Cambio de nombre omitido (no configurado)" -ForegroundColor Gray
}

# ============================================
# RESUMEN Y VERIFICACION FINAL
# ============================================

Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                 CONFIGURACION COMPLETADA                  ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "Resumen de configuración:" -ForegroundColor Yellow
Write-Host ""

# IP
$currentIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -eq $Config.IPAddress}
if ($currentIP) {
    Write-Host "  ✓ IP Address: $($Config.IPAddress)/$($Config.PrefixLength)" -ForegroundColor Green
} else {
    Write-Host "  ✗ IP Address: No configurada" -ForegroundColor Red
}

# Gateway
$gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty NextHop
if ($gateway -eq $Config.Gateway) {
    Write-Host "  ✓ Gateway: $gateway" -ForegroundColor Green
} else {
    Write-Host "  ✗ Gateway: $gateway (esperado: $($Config.Gateway))" -ForegroundColor Yellow
}

# DNS
$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses} | Select-Object -First 1
Write-Host "  ✓ DNS: $($dns.ServerAddresses -join ', ')" -ForegroundColor Green

# WinRM
$winrm = Get-Service WinRM
if ($winrm.Status -eq "Running") {
    Write-Host "  ✓ WinRM: Running (puerto 5985)" -ForegroundColor Green
} else {
    Write-Host "  ✗ WinRM: $($winrm.Status)" -ForegroundColor Red
}

# RDP
$rdp = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
if ($rdp -eq 0) {
    Write-Host "  ✓ RDP: Enabled (puerto 3389)" -ForegroundColor Green
} else {
    Write-Host "  ✗ RDP: Disabled" -ForegroundColor Yellow
}

# Nombre
Write-Host "  ✓ Hostname: $env:COMPUTERNAME" -ForegroundColor Green

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Prueba de conectividad
Write-Host "`nPruebas de conectividad:" -ForegroundColor Yellow

$tests = @(
    @{Name="Gateway"; Host=$Config.Gateway},
    @{Name="Google DNS"; Host="8.8.8.8"}
)

foreach ($test in $tests) {
    $result = Test-Connection -ComputerName $test.Host -Count 1 -Quiet
    if ($result) {
        Write-Host "  ✓ $($test.Name) ($($test.Host)): OK" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($test.Name) ($($test.Host)): Sin respuesta" -ForegroundColor Red
    }
}

# ============================================
# PROXIMO PASO
# ============================================

Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                     PROXIMOS PASOS                        ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

if ($needsReboot) {
    Write-Host "  1. El servidor se reiniciará en 10 segundos..." -ForegroundColor Yellow
    Write-Host "  2. Después del reinicio, ejecuta el playbook de Ansible" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Comando Ansible:" -ForegroundColor White
    Write-Host "  ansible-playbook -i windows/inventory.ini windows/playbooks/windows_ad_dhcp.yml" -ForegroundColor Gray
    Write-Host ""
    
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "  El servidor está listo para Ansible!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Ejecuta desde tu servidor Ansible:" -ForegroundColor Yellow
    Write-Host "  ansible-playbook -i windows/inventory.ini windows/playbooks/windows_ad_dhcp.yml" -ForegroundColor White
    Write-Host ""
    Write-Host "  O si quieres verificar primero:" -ForegroundColor Yellow
    Write-Host "  ansible windows_local -i windows/inventory.ini -m win_ping" -ForegroundColor White
    Write-Host ""
}
