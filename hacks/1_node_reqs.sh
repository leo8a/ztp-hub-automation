#!/usr/bin/env bash
set -xe

# Global variables
export PULL_SECRET_JSON=/vagrant/pull_secret.json
export OCP_RELEASE=4.8.12-x86_64
export OCP_REGISTRY=quay.io/openshift-release-dev/ocp-release


function update_system() {
  dnf -y update
  dnf -y upgrade
}

function download_oc_client() {
  echo "TODO: automate oc from scratch"
  cp /vagrant/binaries/oc /usr/bin/oc

	oc adm --registry-config "${PULL_SECRET_JSON}" release extract \
		--command=oc \
		--from="${OCP_REGISTRY}":"${OCP_RELEASE}" \
		--to .

	if [[ ! -f oc ]]; then
		echo "OC Client wasn't extracted, exiting..."
		exit 1
	fi

	mv oc /usr/bin/oc
}

function download_ipi_installer() {
	oc adm --registry-config "${PULL_SECRET_JSON}" release extract \
		--command=openshift-baremetal-install \
		--from="${OCP_REGISTRY}":"${OCP_RELEASE}" \
		--to .

	if [[ ! -f openshift-baremetal-install ]]; then
		echo "OCP Installer wasn't extracted, exiting..."
		exit 1
	fi

	sudo mv openshift-baremetal-install /usr/bin/openshift-baremetal-install
}

function download_kubectl() {
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/$(uname -m | sed "s/x86_64/amd64/" | sed "s/aarch64/arm64/")/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
}

function get_ket-all() {
  curl -Lo ketall.gz https://github.com/corneliusweig/ketall/releases/download/v1.3.8/ketall-amd64-linux.tar.gz && \
    gunzip ketall.gz && chmod +x ketall && mv ketall "$GOPATH"/bin/
}

function get_tooling() {
  # required tools
  dnf install -y libvirt httpd chrony podman dnsmasq radvd
  download_kubectl
  download_oc_client
  download_ipi_installer

  # nice to have tools
  dnf install -y bash-completion jq tmux vim skopeo libndp ipmitool
  echo "TODO: check ket-all install"
  # get_ket-all
}

function set_kernel_flags() {
  cp /vagrant/templates/etc/sysctl.d/ip.conf /etc/sysctl.d/99-sysctl.conf
  sysctl -p
}


# =============================================================
# 1.1) Hardware / Baseboard Management Controller (BMC) Phase #
# =============================================================
# TODO: Check minimum hardware requirements
# TODO: Install latest BIOS and driver versions
# TODO: Clean up boot entries


# ===========================================
# 1.2) Operating System (OS) / Kernel Phase #
# ===========================================
# 1.2.1) Bastion node bootstrapping
update_system
get_tooling

# 1.2.2) Kernel configurations
set_kernel_flags
