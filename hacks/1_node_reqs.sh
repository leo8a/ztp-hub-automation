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

function get_devtools() {
  # required tools
  dnf install -y libvirt httpd

  # nice to have tools
  dnf install -y bash-completion jq tmux vim podman skopeo
  # TODO: install ndptool ketall
}

function download_oc_client() {
  # TODO: download oc from scratch
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

function disable_slaac() {
  cp /vagrant/templates/etc/sysctl.d/ip.conf /etc/sysctl.d/ip.conf
}


# ===========================
#  1.1) Bootstrapping Phase #
# ===========================
update_system
get_devtools
download_oc_client
download_ipi_installer


# ========================
# 1.2) OS / Kernel Phase #
# ========================
disable_slaac  # this is here due to a node reboot
