#!/usr/bin/env bash
set -xe

# Global variables
export BAREMETAL_IPV6_IFACE=eth0
export BAREMETAL_IPV6_NETWORK=cafe:8a::/64


function set_network_interface() {
  sudo nohup bash -c "
      nmcli con down \"$BAREMETAL_IPV6_IFACE\"
      nmcli con delete \"$BAREMETAL_IPV6_IFACE\"
      # RHEL 8.1 appends the word \"System\" in front of the connection, delete in case it exists
      nmcli con down \"System $BAREMETAL_IPV6_IFACE\"
      nmcli con delete \"System $BAREMETAL_IPV6_IFACE\"
      nmcli connection add ifname baremetal type bridge con-name baremetal
      nmcli con add type bridge-slave ifname \"$BAREMETAL_IPV6_IFACE\" master baremetal
      pkill dhclient;dhclient baremetal
  "
}

function config_radvd() {
  cp /vagrant/templates/etc/radvd.conf /etc/radvd.conf
  sed -i -e "s,BAREMETAL_IPV6_NETWORK,$BAREMETAL_IPV6_NETWORK," /etc/radvd.conf
  systemctl enable radvd --now
}

function check_ra_flag() {
  ra_flag=$(sysctl -p | grep "net.ipv6.conf.all.accept_ra = 2")
  if [ -z "$ra_flag" ]
  then
    echo "Configure kernel host flag to accept RAs for IPv6"
    exit 1
  fi
}

function check_valid_gw() {
  echo "TODO: check for valid IPv6 gateways via RAs and ensure not multiple ones"
  # sudo ndptool monitor -t ra
}

function get_dnsmasq() {
  dnf install -y dnsmasq
  systemctl enable dnsmasq --now
}

function get_chrony() {
  dnf install -y chrony
  systemctl enable chronyd --now
}

function config_chrony() {
  cp /vagrant/templates/etc/chrony.conf /etc/chrony.conf
  systemctl reload-or-restart chronyd
}


# =====================
#  2.1) Layer 2 Phase #
# =====================


# =====================
#  2.2) Layer 3 Phase #
# =====================
# 2.2.1) Configure network interface
set_network_interface

# 2.2.2) Configure RaDVD and SLAAC
config_radvd
check_ra_flag
check_valid_gw

# 2.2.3) Configure DNS, DHCP with dnsmasq, and NTP
get_dnsmasq
#config_dnsmaq
get_chrony
config_chrony


# =====================
#  2.3) Layer 4 Phase #
# =====================
# TODO: Configure External Proxy
# TODO: Configure External Load Balancer
