# 🧰 Ubuntu Server 24.04.3 — Scripts de Configuración Inicial

Este conjunto de scripts automatiza la configuración básica de una máquina virtual o servidor Ubuntu, incluyendo:

1. Creación de usuarios con contraseñas seguras.  
2. Habilitación de acceso SSH solo para ciertos usuarios.  
3. Configuración de servidor FTP (vsftpd) con permisos personalizados.  
4. Asignación de permisos **sudo** a usuarios específicos.

---

## 📁 Estructura de Archivos

```
setup/
├── create_user.sh
├── setup_ssh_allowusers.sh
├── setup_vsftpd_user.sh
├── add_sudoers.sh
└── README.md
```

---

## ⚙️ Requisitos Previos

- Ubuntu 24.04.3 (LTS o Server Edition).  
- Usuario con permisos `sudo` o root.  
- Conexión a internet para instalación de paquetes (`apt-get`).  

> 💡 Todos los scripts deben ejecutarse con `sudo`.

---

## 🧩 1. Crear usuario con contraseña segura

**Script:** `create_user.sh`

Crea un usuario nuevo, asigna una contraseña aleatoria segura (base64) y la muestra junto con su hash SHA256.

```bash
sudo ./create_user.sh <usuario> [--shell /bin/bash]
```

**Ejemplo:**
```bash
sudo ./create_user.sh dev --shell /bin/bash
```

**Salida:**
```
=== Usuario: dev ===
Contraseña (única vez): 4Nc8T+Qs3LPyOr32XH+O...
SHA256(contraseña): 72c4abf3ce3...
================================
```

> Las contraseñas se guardan **temporalmente** en `/root/_user_bootstrap/plain_passwords_once.txt`.  
> ¡Elimínalo después de guardar las credenciales en un gestor seguro!

---

## 🔐 2. Configurar acceso SSH (solo usuarios autorizados)

**Script:** `setup_ssh_allowusers.sh`

Configura `sshd` para permitir **solo ciertos usuarios** (mediante `AllowUsers`).

```bash
sudo ./setup_ssh_allowusers.sh <usuario1> [usuario2 ...]
```

**Ejemplo:**
```bash
sudo ./setup_ssh_allowusers.sh dev ops
```

📁 Esto genera o reemplaza `/etc/ssh/sshd_config.d/99-allowusers.conf` con:
```conf
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AllowUsers dev ops
```

> Reinicia automáticamente `sshd` y habilita el servicio.

---

## 🌐 3. Configurar servidor FTP (vsftpd)

**Script:** `setup_vsftpd_user.sh`

Permite crear un usuario FTP con acceso restringido a un directorio específico, en modo lectura o lectura/escritura.

```bash
sudo ./setup_vsftpd_user.sh --user <usuario> --home <ruta> [--mode ro|rw] [--port 21]
```

**Ejemplos:**

Solo lectura:
```bash
sudo ./setup_vsftpd_user.sh --user filesvc --home /srv/ftp/filesvc --mode ro
```

Lectura y escritura:
```bash
sudo ./setup_vsftpd_user.sh --user filesvc --home /srv/ftp/filesvc --mode rw
```

📄 Genera:
- `/etc/vsftpd.conf` (config global)
- `/etc/vsftpd.userlist` (lista blanca de usuarios)
- `/etc/vsftpd/user_conf/<usuario>` (config individual)

> ⚠️ Asegúrate de abrir los puertos `21` y `30000–30049` en tu firewall.

---

## 👑 4. Agregar permisos Sudo a un usuario

**Script:** `add_sudoers.sh`

Agrega un usuario existente al grupo `sudo` y crea un archivo sudoers dedicado.

```bash
sudo ./add_sudoers.sh <usuario> [--nopass]
```

**Ejemplos:**

Con solicitud de contraseña:
```bash
sudo ./add_sudoers.sh dev
```

Sin solicitud de contraseña:
```bash
sudo ./add_sudoers.sh dev --nopass
```

📁 Crea `/etc/sudoers.d/99-<usuario>` con:
```
dev ALL=(ALL) NOPASSWD:ALL
```
*(si se usa `--nopass`)*

---

## 🧭 Orden sugerido de ejecución

```bash
# 1. Crear usuarios
sudo ./create_user.sh dev
sudo ./create_user.sh ops

# 2. Configurar SSH (solo para usuarios permitidos)
sudo ./setup_ssh_allowusers.sh dev ops

# 3. (Opcional) Configurar FTP para un usuario
sudo ./setup_vsftpd_user.sh --user filesvc --home /srv/ftp/filesvc --mode ro

# 4. Dar permisos sudo
sudo ./add_sudoers.sh dev --nopass
```

---

## 🧹 Limpieza y seguridad

- Elimina `/root/_user_bootstrap/plain_passwords_once.txt` tras guardar las contraseñas.  
- Revisa los logs y backups de configuración en `/etc/ssh/sshd_config.d/*.bak.*` y `/etc/vsftpd.conf.bak.*`.  
- Usa claves SSH en lugar de contraseñas siempre que sea posible.

---

## 📜 Licencia

Uso interno o educativo — libre de modificar, redistribuir y versionar bajo tu propio control.  
Se recomienda mantener un control de versiones (Git) para trazabilidad de cambios.
