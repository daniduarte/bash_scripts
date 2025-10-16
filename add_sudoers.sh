#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Uso: sudo $0 <usuario> [--nopass]"
  echo "Añade el usuario al grupo 'sudo' y crea sudoers en /etc/sudoers.d/"
  exit 1
}

[[ $# -lt 1 ]] && usage
USER_NAME="$1"; shift || true
NOPASS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --nopass) NOPASS=true; shift ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

if ! id "$USER_NAME" &>/dev/null; then
  echo "[ERR] El usuario '$USER_NAME' no existe. Créalo primero."
  exit 2
fi

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo

usermod -aG sudo "$USER_NAME"

DROP="/etc/sudoers.d/99-${USER_NAME}"
cp -a "$DROP" "${DROP}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

if $NOPASS; then
  echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > "$DROP"
else
  echo "${USER_NAME} ALL=(ALL) ALL" > "$DROP"
fi

chmod 440 "$DROP"

echo "[OK] Usuario '$USER_NAME' agregado a 'sudo'. NOPASS=$NOPASS"
