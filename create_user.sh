#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Uso: sudo $0 <usuario> [--shell /bin/bash]"
  exit 1
}

[[ $# -lt 1 ]] && usage
USER_NAME="$1"; shift || true
SHELL_BIN="/bin/bash"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell) SHELL_BIN="${2:-/bin/bash}"; shift 2 ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

if id "$USER_NAME" &>/dev/null; then
  echo "[INFO] Usuario '$USER_NAME' ya existe, actualizando shell -> $SHELL_BIN"
  chsh -s "$SHELL_BIN" "$USER_NAME" || true
else
  adduser --disabled-password --gecos "" "$USER_NAME"
  usermod -s "$SHELL_BIN" "$USER_NAME"
  echo "[OK] Usuario '$USER_NAME' creado con shell $SHELL_BIN"
fi

# Generar contraseña segura y asignar
PW="$(openssl rand -base64 18)"
echo "${USER_NAME}:${PW}" | chpasswd
HASH="$(printf '%s' "$PW" | sha256sum | awk '{print $1}')"

# Guardar de forma segura para que la copies (bórralo después)
OUT_DIR="/root/_user_bootstrap"
mkdir -p "$OUT_DIR"
echo "${USER_NAME}:${PW}" >> "$OUT_DIR/plain_passwords_once.txt"
echo "\"${USER_NAME}\": \"${HASH}\"" >> "$OUT_DIR/sha256_hashes.txt"

echo
echo "=== Usuario: ${USER_NAME} ==="
echo "Contraseña (cópiala AHORA y luego borra /root/_user_bootstrap/plain_passwords_once.txt): ${PW}"
echo "SHA256(contraseña): ${HASH}"
echo "================================"
