# Playbook: ESXi — Create GameCenter VMs

Crea máquinas virtuales desde cero en ESXi para el proyecto GameCenter: Fedora (Bazzite), Windows 11 y Windows Server. Configura hardware, NICs, monta ISOs y enciende las VMs.

## Hosts target

- Grupo: `esxi_hosts`
- Conexión: `local`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `esxi_host` | group_vars/esxi_hosts | IP/hostname del ESXi (168.121.48.254:10120) |
| `esxi_user` | group_vars/esxi_hosts | Usuario |
| `esxi_pass` | group_vars/esxi_hosts/vault.yml | Password |
| `validate_certs` | group_vars/esxi_hosts | false |
| `datacenter_name` | group_vars/esxi_hosts | Datacenter |
| `ds_name` | group_vars/esxi_hosts | Datastore |
| `resource_pool_name` | group_vars/esxi_hosts | Resource pool |

### VMs creadas

| VM | SO | vCPU | RAM | Disco | ISO |
|---|---|---|---|---|---|
| Bazzite_pc02_G01 | Fedora | 4 | 8GB | 60GB | bazzite-stable-amd64.iso |
| Windows11pro_pc01_G01 | Windows 11 | 4 | 8GB | 60GB | Win11_25H2_Spanish_x64.iso |
| WindowsServer_G01 | Windows Server 2016+ | 4 | 8GB | 50GB | WindowsServer2022_64bit.iso |

## Dependencias

- Colección: `community.vmware`
- Archivos ISO en el datastore del ESXi (en `{{ ds_name }}/{{ iso_folder }}/`)
- Tasks file: `mount_iso.yml` (incluido vía include_tasks)

## Flujo

1. Crear VMs con hardware y disco
2. Configurar NICs
3. Apagar VMs
4. Montar ISOs (con fallback IDE → SATA)
5. Encender VMs
6. Mostrar información de dispositivos

## Orden de ejecución

- Independiente. Requiere ISOs en el datastore

## Uso

```bash
ansible-playbook playbooks/esxi/create_gamecenter_vms.yml
```
