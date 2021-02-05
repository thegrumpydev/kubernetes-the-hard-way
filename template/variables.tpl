---
public_ip: ${public_ip}
controllers:
%{ for host in controllers ~}
  - name: ${host.name}
    public_ip: ${host.network_interface[0].access_config[0].nat_ip}
    private_ip: ${host.network_interface[0].network_ip}
%{ endfor ~}
workers:
%{ for host in workers ~}
  - name: ${host.name}
    public_ip: ${host.network_interface[0].access_config[0].nat_ip}
    private_ip: ${host.network_interface[0].network_ip}
%{ endfor ~}
data_dir: data
certs_dir: certs
