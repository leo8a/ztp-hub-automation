#!/usr/bin/env bash
set -xe

# Global variables
export PULL_SECRET_JSON=/vagrant/pull_secret.json
export BAREMETAL_IPV6_NETWORK=cafe:8a::/64


function get_ndpmon() {
  echo "TODO: Install ndpmon"
}

function config_radvd() {
  cp /vagrant/templates/etc/radvd.conf /etc/radvd.conf
  sed -i -e "s,BAREMETAL_IPV6_NETWORK,$BAREMETAL_IPV6_NETWORK," /etc/radvd.conf
}

function check_ra() {
  echo "TODO: check for RA's that include managed flag"
}

function check_valid_gw() {
  echo "TODO: check for valid IPv6 gateways via RAs and ensure not multiple ones"
}


# =====================
#  2.1) Layer 2 Phase #
# =====================


# =====================
#  2.2) Layer 3 Phase #
# =====================
# 2.2.1) Configure DNS, DHCP, and NTP

# 2.2.2) Configure RaDVD and SLAAC
get_ndpmon
config_radvd
check_ra
check_valid_gw


# =====================
#  2.3) Layer 4 Phase #
# =====================
