[controllers]
%{ for host in controllers ~}
${host.name} ansible_host=${host.network_interface[0].access_config[0].nat_ip} private_ip=${host.network_interface[0].network_ip}
%{ endfor ~}

[workers]
%{ for host in workers ~}
${host.name} ansible_host=${host.network_interface[0].access_config[0].nat_ip} private_ip=${host.network_interface[0].network_ip} pod_cidr=${host.metadata.pod-cidr}
%{ endfor ~}
