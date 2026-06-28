# Sustento de Diseño VLSM — Datacenter Norcom

## Supernet general

| Bloque       | Uso                              |
|--------------|----------------------------------|
| `192.168.0.0/16` | Espacio de direccionamiento interno completo |
| `172.17.25.0/24` | Enlace WAN1 (ISP1)           |
| `168.17.25.0/29` | Enlace WAN2 (ISP2)           |

El espacio `192.168.0.0/16` se divide con VLSM para asignar a cada segmento exactamente el tamaño que justifica su rol, evitando el desperdicio de un esquema classful.

---

## Segmentos WAN

### WAN1 — `172.17.25.0/24` (máscara /24)

| Campo        | Valor              |
|--------------|--------------------|
| Red          | 172.17.25.0/24     |
| Máscara      | 255.255.255.0      |
| Hosts útiles | 254                |
| Gateway ISP1 | 172.17.25.121      |
| Router MASTER| 172.17.25.81 (pfSense) / 172.17.25.86 (Ubuntu) |
| Router BACKUP| 172.17.25.83 (pfSense) |

**Argumento de máscara:** El proveedor ISP1 asigna un bloque /24 de su segmento de gestión. Esta subred no es diseñada por Norcom sino dictada por el ISP; un /24 es estándar en enlaces de acceso empresarial donde el proveedor administra múltiples CPEs y equipos propios dentro del mismo rango.

---

### WAN2 — `168.17.25.0/29` (máscara /29)

| Campo        | Valor              |
|--------------|--------------------|
| Red          | 168.17.25.0/29     |
| Máscara      | 255.255.255.248    |
| Hosts útiles | 6                  |
| Gateway ISP2 | 168.17.25.1        |
| Router MASTER| 168.17.25.2        |
| Router BACKUP| 168.17.25.3        |

**Argumento de máscara:** El enlace secundario WAN2 es un punto a punto ampliado donde solo participan el gateway del ISP y los dos routers del datacenter (MASTER y BACKUP). Un /29 otorga exactamente 6 direcciones útiles, suficientes para: gateway ISP (`.1`), router MASTER (`.2`), router BACKUP (`.3`) y 3 de reserva para crecimiento. Usar una subred mayor sería un desperdicio ya que es un enlace dedicado de tránsito.

---

## Segmentos internos por VLAN

### VLAN 10 — SERVIDORES — `192.168.10.0/26` (máscara /26)

| Campo           | Valor                        |
|-----------------|------------------------------|
| Red             | 192.168.10.0/26              |
| Máscara         | 255.255.255.192              |
| Rango útil      | 192.168.10.1 – 192.168.10.62 |
| Broadcast       | 192.168.10.63                |
| Hosts útiles    | 62                           |
| Gateway (VIP VRRP/CARP) | 192.168.10.1         |
| Router MASTER   | 192.168.10.2                 |
| Router BACKUP   | 192.168.10.3                 |
| DC1 / DNS Primario (Windows Server) | 192.168.10.5 |
| DNS Secundario (Ubuntu BIND9) | 192.168.10.6   |
| Mail Server (Ubuntu iRedMail) | 192.168.10.9   |
| Relay DHCP destino | 192.168.10.5              |

**Argumento de máscara:** La VLAN de servidores aloja infraestructura fija: controlador de dominio, DNS primario y secundario, servidor de correo, servidor de archivos y monitoreo. El número de servidores en un datacenter mediano no suele exceder los 30–40 hosts, y su crecimiento es planificado (no orgánico como en redes de usuarios). Un /26 con 62 hosts útiles es suficiente para todos los servicios actuales con margen de crecimiento sin comprometer el espacio de las VLANs de usuarios. Usar un /25 o /24 desperdiciaría más de 100 o 190 direcciones en un segmento donde cada host es un servidor administrado con IP estática conocida.

---

### VLAN 20 — ADMINISTRACIÓN — `192.168.20.0/25` (máscara /25)

| Campo           | Valor                          |
|-----------------|--------------------------------|
| Red             | 192.168.20.0/25                |
| Máscara         | 255.255.255.128                |
| Rango útil      | 192.168.20.1 – 192.168.20.126  |
| Broadcast       | 192.168.20.127                 |
| Hosts útiles    | 126                            |
| Gateway (VIP VRRP/CARP) | 192.168.20.1           |
| Router MASTER   | 192.168.20.2                   |
| Router BACKUP   | 192.168.20.3                   |
| Rango DHCP      | 192.168.20.50 – 192.168.20.120 |
| WAN de salida   | WAN1 (ISP1)                    |

**Argumento de máscara:** El departamento de Administración concentra el mayor nivel de privilegios dentro de la red: tiene acceso inter-VLAN a todas las demás VLANs. Un /25 con 126 hosts útiles anticipa una cantidad media-alta de estaciones de trabajo (PCs de escritorio, laptops gerenciales, teléfonos IP, impresoras de red). El rango DHCP asignado (`.50`–`.120`) reserva las primeras 49 direcciones para equipos con IP estática (impresoras, APs de administración, dispositivos VoIP fijos) sin necesidad de reconfigurar el scope. Se eligió /25 en lugar de /24 porque el espacio `192.168.20.128–192.168.20.255` queda disponible para expansión futura si Administración crece, sin necesidad de re-numerar la red.

---

### VLAN 30 — TI — `192.168.30.0/26` (máscara /26)

| Campo           | Valor                        |
|-----------------|------------------------------|
| Red             | 192.168.30.0/26              |
| Máscara         | 255.255.255.192              |
| Rango útil      | 192.168.30.1 – 192.168.30.62 |
| Broadcast       | 192.168.30.63                |
| Hosts útiles    | 62                           |
| Gateway (VIP VRRP/CARP) | 192.168.30.1         |
| Router MASTER   | 192.168.30.2                 |
| Router BACKUP   | 192.168.30.3                 |
| Rango DHCP      | 192.168.30.30 – 192.168.30.60|
| WAN de salida   | WAN2 (ISP2)                  |

**Argumento de máscara:** El departamento de TI es típicamente el más reducido en personal pero con alta densidad de dispositivos por persona (laptop, equipo de pruebas, máquinas virtuales con IPs en el mismo segmento, etc.). Un /26 con 62 hosts útiles es adecuado: el equipo de TI no suele superar 20–25 personas, y los dispositivos extra por persona (máquinas de laboratorio, switches gestionados, APs de prueba) se ubican igualmente dentro de ese rango. El rango DHCP más acotado (`.30`–`.60`) refleja que TI tiene menos usuarios que Administración pero mantiene margen para equipos de laboratorio temporal. La separación en /26 en lugar de /25 también aísla la red de TI en un bloque más pequeño, reduciendo el dominio de broadcast y mejorando la seguridad del segmento que gestiona toda la infraestructura.

---

### VLAN 40 — VENTAS — `192.168.40.0/25` (máscara /25)

| Campo           | Valor                          |
|-----------------|--------------------------------|
| Red             | 192.168.40.0/25                |
| Máscara         | 255.255.255.128                |
| Rango útil      | 192.168.40.1 – 192.168.40.126  |
| Broadcast       | 192.168.40.127                 |
| Hosts útiles    | 126                            |
| Gateway (VIP VRRP/CARP) | 192.168.40.1           |
| Router MASTER   | 192.168.40.2                   |
| Router BACKUP   | 192.168.40.3                   |
| Rango DHCP      | 192.168.40.50 – 192.168.40.120 |
| WAN de salida   | WAN2 (ISP2)                    |

**Argumento de máscara:** Ventas suele ser el departamento de usuarios finales más numeroso en una empresa: involucra personal de campo, representantes, supervisores y en muchos contextos dispositivos móviles (tablets, teléfonos corporativos) que también consumen direcciones IP. Un /25 con 126 hosts útiles acomoda este crecimiento. Comparte el mismo prefijo /25 que Administración porque tienen perfiles de tamaño similares, pero se diferencian en: política de acceso inter-VLAN (Ventas solo puede alcanzar SERVIDORES, no Administración ni TI), WAN de salida (WAN2 en lugar de WAN1) y el hecho de que sus usuarios no tienen privilegios administrativos sobre la red. El rango DHCP `.50`–`.120` reserva las primeras 49 IPs para impresoras de ventas, terminales POS u otros dispositivos fijos.

---

## Resumen comparativo

| VLAN | Nombre        | Subred              | Máscara             | Hosts útiles | Criterio de tamaño           |
|------|---------------|---------------------|---------------------|--------------|------------------------------|
| —    | WAN1 (ISP1)   | 172.17.25.0/24      | 255.255.255.0       | 254          | Asignado por ISP             |
| —    | WAN2 (ISP2)   | 168.17.25.0/29      | 255.255.255.248     | 6            | Enlace de tránsito con 2 routers + gateway |
| 10   | SERVIDORES    | 192.168.10.0**/26** | 255.255.255.192     | 62           | Infraestructura fija, bajo crecimiento |
| 20   | ADMINISTRACIÓN| 192.168.20.0**/25** | 255.255.255.128     | 126          | Departamento medio, acceso privilegiado |
| 30   | TI            | 192.168.30.0**/26** | 255.255.255.192     | 62           | Equipo pequeño, alta densidad de dispositivos por persona |
| 40   | VENTAS        | 192.168.40.0**/25** | 255.255.255.128     | 126          | Mayor volumen de usuarios finales y dispositivos móviles |

---

## Política de acceso inter-VLAN y relación con el diseño

El tamaño de cada subred también refleja su nivel de confianza en la política de firewall:

- **SERVIDORES /26** — zona DMZ interna: recibe tráfico de todas las VLANs pero no inicia conexiones hacia ellas. Subred pequeña y controlada.
- **ADMINISTRACIÓN /25** — zona privilegiada: puede acceder a SERVIDORES, TI y VENTAS. Necesita más hosts por la cantidad de equipos administrativos.
- **TI /26** — zona técnica: acceso completo a todas las VLANs para gestión. Subred reducida pero no restringida en políticas.
- **VENTAS /25** — zona de usuarios: solo puede acceder a SERVIDORES (para servicios de correo, archivos y dominio). Es la más poblada en usuarios pero la más limitada en permisos.
