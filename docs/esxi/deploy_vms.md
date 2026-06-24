# Playbook: ESXi — Deploy VMs (OVF/OVA)

Despliega máquinas virtuales desde archivos OVF/OVA almacenados en disco local del servidor Ansible. Soporta redes personalizadas, thin provisioning y power-on automático.

## Hosts target

- Grupo: `esxi_hosts`
- Conexión: `local`

## Variables

| Variable | Origen | Descripción |
|---|---|---|
| `esxi_host` | group_vars/esxi_hosts | IP/hostname del ESXi |
| `esxi_port` | group_vars/esxi_hosts | Puerto |
| `esxi_user` | group_vars/esxi_hosts | Usuario |
| `esxi_pass` | group_vars/esxi_hosts/vault.yml | Password |
| `validate_certs` | group_vars/esxi_hosts | false |
| `datacenter_name` | group_vars/esxi_hosts | Datacenter |
| `ds_name` | group_vars/esxi_hosts | Datastore |
| `resource_pool_name` | group_vars/esxi_hosts | Resource pool |
| `vm_defs` | vars del play | Lista de definiciones de VM |

## Dependencias

- Colección: `community.vmware`
- Archivos OVF/OVA accesibles desde la ruta local del servidor Ansible

## Orden de ejecución

- Independiente. Requiere que los archivos OVF/OVA existan en la ruta especificada

## Uso

```bash
ansible-playbook playbooks/esxi/deploy_vms.yml
```
