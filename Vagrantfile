# -*- mode: ruby -*-
# vi: set ft=ruby :


# =======================
# Define user variables #
# =======================
OCP_RELEASE = "4.9.8-x86_64"
OCP_REGISTRY = "quay.io/openshift-release-dev/ocp-release"

REFRESH_ALL = false
ARTIFACTORY_ENABLED = false
PULL_SECRET_PATH = "/vagrant/pull_secret.json"

ZTP_HUB_CLUSTER_NODES = {
            'master-0': { 'ip': '1e0:8a::10',
                          'mac': 'aa:aa:aa:aa:bb:01',
                          'hostname': 'master-0.cluster.leo8a.io' },
            'master-1': { 'ip': '1eo:8a::11',
                          'mac': 'aa:aa:aa:aa:bb:02',
                          'hostname': 'master-1.cluster.leo8a.io' },
            'master-2': { 'ip': '1e0:8a::12',
                          'mac': 'aa:aa:aa:aa:bb:03',
                          'hostname': 'master-2.cluster.leo8a.io' } }


# ======================
# Define box variables #
# ======================
IMAGE_NAME = "generic/rhel8"
USE_PLAYBOOKS_ON_BOOT = false

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vbguest.auto_update = false

  # config.vm.network "private_network", type: "dhcp"       # (eth0) outbound Internet connectivity via NAT
  config.vm.network "private_network", ip: "192.168.56.5"   # (eth1) baremetal network

  config.vm.provider "virtualbox" do |v|
    v.memory = 5120
    v.cpus = 2
  end

  config.vm.define "ztp-bastion" do |bastion|
    bastion.vm.box = IMAGE_NAME

    bastion.vm.hostname = "bastion.leo8a.io"
    bastion.vm.synced_folder ".", "/vagrant", type: "rsync"
  end

  if USE_PLAYBOOKS_ON_BOOT
      # node requirements
      config.vm.provision "ansible" do |ansible|
        ansible.playbook = "automation/node-requirements.yml"
        ansible.extra_vars = {
            ocp_release: OCP_RELEASE,
            ocp_registry: OCP_REGISTRY,
            refresh_oc_tools: REFRESH_ALL,
            pull_secret_path: PULL_SECRET_PATH
            }
      end

      # network requirements
      config.vm.provision "ansible" do |ansible|
        ansible.playbook = "automation/network-requirements.yml"
        ansible.extra_vars = {
            bastion_nic: "eth0",
            bastion_ipv6_mask: "64",
            bastion_ipv6_ip: "1e0:8a::5",
            bastion_ipv6_cidr: "1e0:8a::/64",
            bastion_ipv6_start: "1e0:8a::3",
            bastion_ipv6_end: "1e0:8a::30",
            bastion_cluster_network: "baremetal",
            refresh_bastion_interfaces: REFRESH_ALL,
            ztp_hub_cluster_nodes: ZTP_HUB_CLUSTER_NODES,
            cluster_name: 'ztp-cluster0',
            cluster_domain: 'leo8a.io',
            cluster_baremetal_cidr: '1e0:8a::/64',
            cluster_baremetal_api_ip: '1e0:8a::25/64',
            cluster_baremetal_ingress_ip: '1e0:8a::26/64'
        }
      end

      # ztp-bastion service's requirements
      config.vm.provision "ansible" do |ansible|
        ansible.playbook = "automation/services-requirements.yml"
        ansible.extra_vars = {
            ocp_release: OCP_RELEASE,
            ocp_registry: OCP_REGISTRY,
            local_registry_user: "dummy",
            refresh_rhcos_images: "false",
            local_repository_name: "ocp4",
            local_registry_password: "dummy",
            pull_secret_path: PULL_SECRET_PATH,
            on_prem_artifactory: ARTIFACTORY_ENABLED
            }
      end

  else
      config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
          get_ansible() {
          dnf -y install ansible
          ansible-galaxy install robertdebock.dnsmasq
          ansible-galaxy collection install community.general
          }

          # bootstrapping workflow
          get_ansible
      SHELL

  end
end
