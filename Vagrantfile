# -*- mode: ruby -*-
# vi: set ft=ruby :

# Define the image box
IMAGE_NAME = "generic/rhel8"


Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vbguest.auto_update = false

  config.vm.network "forwarded_port", guest: 80, host: 8080    # Local HTTP server
  config.vm.network "forwarded_port", guest: 3000, host: 3000  # Repository server
  config.vm.network "forwarded_port", guest: 5000, host: 5000  # Disconnected registry

  config.vm.provider "virtualbox" do |v|
    v.memory = 5120
    v.cpus = 2
  end

  config.vm.define "ztp-bastion" do |bastion|
    bastion.vm.box = IMAGE_NAME

    bastion.vm.hostname = "bastion.leo8a.io"
    bastion.vm.synced_folder ".", "/vagrant", type: "rsync"
  end

  # node requirements
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "automation/node-requirements.yml"
  end

  # network requirements
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "automation/network-requirements.yml"
    ansible.extra_vars = {
        bastion_nic: "eth0",
        bastion_ipv6_mask: "64",
        bastion_ipv6_ip: "cafe:8a::5",
        bastion_ipv6_cidr: "cafe:8a::/64",
        bastion_cluster_network: "baremetal"
    }
  end

  # helper service's requirements

end
