#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Uso: sudo $0 <usuario1> [usuario2 ...]"
  echo "Configura SSH para permitir SOLO los usuarios indicados (AllowUsers)."
  exit 1
}

[[ $# -lt 1 ]] && usage

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server

mkdir -p /etc/ssh/sshd_config.d
CONF="/etc/ssh/sshd_config_doesnotexist" # dummy to avoid glob issues
CONF_DIR="/etc/ssh/sshd_config.d"
SNIPPET="${CONF_DIR}/99-allowusers.conf"

# backup previo
[[ -f "$SNIPPET" ]] && cp -a "$SNIPPET" "${SNIPPET}.bak.$(date +%Y%m%d%H%M%S)"

{
  echo "# Administrado por setup_ssh_allowusers.sh"
  echo "PermitRootLogin no"
  echo "PasswordAuthentication yes"
  echo "PubkeyAuthentication yes"
  echo -n "AllowUsers"
  for u in "$@"; do
    echo -n " $u"
  done
  echo
} > "$SNIPPET"

systemctl enable --now ssh
systemctl restart ssh

echo "[OK] SSH configurado. SOLO pueden acceder: $*"
