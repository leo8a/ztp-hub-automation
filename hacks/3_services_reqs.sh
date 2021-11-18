#!/usr/bin/env bash

# Global variables
export OCP_RELEASE=4.8.12-x86_64


function get_http() {
  dnf install -y httpd
  systemctl enable httpd --now
}

function get_libvirt() {
  dnf install -y libvirt
  systemctl enable libvirt --now
}

function download_rhcos() {
	export RHCOS_VERSION=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["release"]')
	export RHCOS_ISO_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["formats"]["iso"]["disk"]["location"]')
	export RHCOS_ROOT_FS=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["formats"]["pxe"]["rootfs"]["location"]')
	export RHCOS_QEMU_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["qemu"]["formats"]["qcow2.gz"]["disk"]["location"]')
	export RHCOS_QEMU_SHA_UNCOMPRESSED=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["qemu"]["formats"]["qcow2.gz"]["disk"]["uncompressed-sha256"]')
	export RHCOS_OPENSTACK_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["openstack"]["formats"]["qcow2.gz"]["disk"]["location"]')
	export RHCOS_OPENSTACK_SHA_COMPRESSED=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["openstack"]["formats"]["qcow2.gz"]["disk"]["sha256"]')
	export OCP_RELEASE_DOWN_PATH=/var/www/html/$OCP_RELEASE

	echo "RHCOS_VERSION: $RHCOS_VERSION"
	echo "RHCOS_OPENSTACK_URI: $RHCOS_OPENSTACK_URI"
	echo "RHCOS_OPENSTACK_SHA_COMPRESSED: ${RHCOS_OPENSTACK_SHA_COMPRESSED}"
	echo "RHCOS_QEMU_URI: $RHCOS_QEMU_URI"
	echo "RHCOS_QEMU_SHA_UNCOMPRESSED: $RHCOS_QEMU_SHA_UNCOMPRESSED"
	echo "RHCOS_ISO_URI: $RHCOS_ISO_URI"
	echo "RHCOS_ROOT_FS: $RHCOS_ROOT_FS"
	echo "Press Enter to continue or Ctrl-C to cancel download"

	if [[ ! -d ${OCP_RELEASE_DOWN_PATH} ]]; then
		echo "----> Downloading RHCOS resources to ${OCP_RELEASE_DOWN_PATH}"
		sudo mkdir -p "${OCP_RELEASE_DOWN_PATH}"
		echo "--> Downloading RHCOS resources: RHCOS QEMU Image"
		sudo curl -s -L -o "${OCP_RELEASE_DOWN_PATH}"/$(echo "$RHCOS_QEMU_URI" | xargs basename) "${RHCOS_QEMU_URI}"
		echo "--> Downloading RHCOS resources: RHCOS Openstack Image"
		sudo curl -s -L -o "${OCP_RELEASE_DOWN_PATH}"/$(echo "$RHCOS_OPENSTACK_URI" | xargs basename) "${RHCOS_OPENSTACK_URI}"
		echo "--> Downloading RHCOS resources: RHCOS ISO"
		sudo curl -s -L -o "${OCP_RELEASE_DOWN_PATH}"/$(echo "$RHCOS_ISO_URI" | xargs basename) "${RHCOS_ISO_URI}"
		echo "--> Downloading RHCOS resources: RHCOS RootFS"
		sudo curl -s -L -o "${OCP_RELEASE_DOWN_PATH}"/$(echo "$RHCOS_ROOT_FS" | xargs basename) "${RHCOS_ROOT_FS}"
	else
		echo "The folder already exist, so delete it if you want to re-download the RHCOS resources"
	fi
}

function check_http() {
  echo "TODO: implement a check"
}


# ===============================
#  3.1) Local HTTP server Phase #
# ===============================
get_http
get_libvirt
download_rhcos
check_http


# ===============================
#  3.2) Local HTTP server Phase #
# ===============================
