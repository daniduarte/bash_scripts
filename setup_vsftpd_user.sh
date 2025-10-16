#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Uso: sudo $0 --user <usuario> --home <dir> [--mode ro|rw] [--port 21]"
  echo "Ejemplo: sudo $0 --user filesvc --home /srv/ftp/filesvc --mode ro --port 21"
  exit 1
}

USER_FTP=""
FTP_HOME=""
MODE="ro"
PORT="21"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USER_FTP="${2:-}"; shift 2 ;;
    --home) FTP_HOME="${2:-}"; shift 2 ;;
    --mode) MODE="${2:-ro}"; shift 2 ;;
    --port) PORT="${2:-21}"; shift 2 ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

[[ -z "$USER_FTP" || -z "$FTP_HOME" ]] && usage
[[ "$MODE" =~ ^(ro|rw)$ ]] || { echo "Modo inválido: $MODE (usa ro|rw)"; exit 1; }

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y vsftpd ssl-cert

# Crear usuario si no existe, con shell nologin
if id "$USER_FTP" &>/dev/null; then
  echo "[INFO] Usuario '$USER_FTP' ya existe."
else
  adduser --disabled-password --gecos "" "$USER_FTP"
fi
usermod -s /usr/sbin/nologin "$USER_FTP" || true

# Asegurar HOME/chroot
mkdir -p "$FTP_HOME"
chown -R "$USER_FTP":"$USER_FTP" "$FTP_HOME"
chmod 755 "$FTP_HOME"

# Config global vsftpd
cp -a /etc/vsftpd.conf "/etc/vsftpd.conf.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
cat > /etc/vsftpd.conf <<CFG
# Administrado por setup_vsftpd_user.sh
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO

chroot_local_user=YES
allow_writeable_chroot=YES

userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd.userlist

user_config_dir=/etc/vsftpd/user_conf

xferlog_std_format=YES
listen_port=${PORT}
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30049
CFG

# Habilitar solo el usuario indicado
echo "$USER_FTP" > /etc/vsftpd.userlist

# Config por-usuario
mkdir -p /etc/vsftpd/user_conf
UCONF="/etc/vsftpd/user_conf/${USER_FTP}"
cat > "$UCONF" <<EOC
local_root=${FTP_HOME}
write_enable=$( [[ "$MODE" == "rw" ]] && echo YES || echo NO )
EOC

systemctl enable --now vsftpd
systemctl restart vsftpd

echo "[OK] vsftpd listo. Usuario=${USER_FTP}, home=${FTP_HOME}, modo=${MODE}, puerto=${PORT}"
echo "[AVISO] Abre puertos 21 y 30000-30049 en firewall/red si corresponde."
