# -*- mode: ruby -*-
# vi: set ft=ruby :

# Define the image box
IMAGE_NAME = "generic/rhel8"


Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vbguest.auto_update = false

  config.vm.network "forwarded_port", guest: 80, host: 8080    # HTTP server
  config.vm.network "forwarded_port", guest: 3000, host: 3000  # Gogs repository server
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
  config.vm.provision "node", type: "shell", path: "hacks/1_node_reqs.sh"
  config.vm.provision :reload

  # network requirements
  config.vm.provision "network", type: "shell", path: "hacks/2_network_reqs.sh"

  # helper service's requirements
  config.vm.provision "services", type: "shell", path: "hacks/3_services_reqs.sh"

end
