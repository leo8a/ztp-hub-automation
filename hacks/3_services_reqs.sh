#!/usr/bin/env bash

# Global variables
export PULL_SECRET_JSON=/vagrant/pull_secret.json

export OCP_RELEASE=4.8.12-x86_64
export OCP_REGISTRY=quay.io/openshift-release-dev/ocp-release
export LOCAL_REPOSITORY=ocp4
export LOCAL_REGISTRY=$(hostname):5000

export GOGS_BASE_FOLDER=/opt/gogs
export BASTION_IPV6_ADDRESS=cafe:8a::10/64


function get_http() {
  dnf install -y httpd
  systemctl enable httpd --now
}

function get_libvirt() {
  dnf install -y libvirt
  systemctl enable libvirtd --now
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
	echo "Press Ctrl-C to cancel download"

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

function get_podman() {
  dnf install -y podman
  systemctl start podman
  systemctl enable podman
}

function generate_self_signed_certs() {
  mkdir -p /opt/registry/{auth,certs,data}

  host_fqdn=$( hostname --long )
  cert_c="US"                  # Country Name (C, 2 letter code)
  cert_s="Sands Point, NY"     # Certificate State (S)
  cert_l="235 Middle Neck Rd." # Certificate Locality (L)
  cert_o="Gatsby Home"         # Certificate Organization (O)
  cert_ou="Gatsby Inc"         # Certificate Organizational Unit (OU)
  cert_cn="${host_fqdn}"       # Certificate Common Name (CN)

  openssl req \
      -newkey rsa:4096 \
      -nodes \
      -sha256 \
      -keyout /opt/registry/certs/domain.key \
      -x509 \
      -days 365 \
      -out /opt/registry/certs/domain.crt \
      -addext "subjectAltName = DNS:${host_fqdn}" \
      -subj "/C=${cert_c}/ST=${cert_s}/L=${cert_l}/O=${cert_o}/OU=${cert_ou}/CN=${cert_cn}"

  cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract
}

function start_disconnected_registry() {
  htpasswd -bBc /opt/registry/auth/htpasswd redhat redhat

  podman create \
    --name disconnected-registry \
    -p 5000:5000 \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
    -e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
    -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
    -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
    -e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
    -e "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true" \
    -v /opt/registry/data:/var/lib/registry:z \
    -v /opt/registry/auth:/auth:z \
    -v /opt/registry/certs:/certs:z \
    docker.io/library/registry:2

  podman start disconnected-registry
}

function mirror_release() {
	echo "----> Mirroring OCP Release: ${OCP_RELEASE}"
	oc adm -a ${PULL_SECRET_JSON} release mirror \
	       --from="${OCP_REGISTRY}":${OCP_RELEASE} \
	       --to="${LOCAL_REGISTRY}"/"${LOCAL_REPOSITORY}" \
	       --to-release-image="${LOCAL_REGISTRY}"/"${LOCAL_REPOSITORY}":${OCP_RELEASE}
}

function start_gogs() {
  mkdir -pv "${GOGS_BASE_FOLDER}"

  podman run -d \
    --network=host \
    --privileged \
    --name gogs \
    -p 8022:22 \
    -p 3000:3000 \
    -v /opt/gogs:/data \
    docker.io/gogs/gogs

  echo "Access the url http://[$BASTION_IPV6_ADDRESS]:3000 to configure Gogs"
}


# ===============================
#  3.1) Local HTTP server Phase #
# ===============================
get_http
get_libvirt
download_rhcos
check_http


# ===================================
#  3.2) Disconnected Registry Phase #
# ===================================
get_podman
generate_self_signed_certs
start_disconnected_registry
mirror_release


# ==============================
#  3.3) Local Repository Phase #
# ==============================
get_podman
start_gogs


# ============================================
#  3.4) On-prem Artifactory Phase (optional) #
# ============================================
# TODO: automate JFrog install and configuration
