# Script de configuración automática de Rclone con Google Drive

Este script en .sh te ayuda a:

- Instalar la versión "v1.70.2" de RCLONE
- Conectar tu Google Drive mediante un `remote`
- Configurar alias (`uploadrive` y `downloadrive`) en tu shell
- Sincronizar fácilmente archivos entre tu PC y Google Drive
- Usar los alias personalizados para subir o bajar archivos desde el PC al DRIVE o del DRIVE al PC.

---

## 📦 Requisitos

- Linux (testeado en ArchLinux)
- `curl` y `unzip`.
- Tener una cuenta de Google Drive
- Permisos `sudo` (para instalar rclone si no está)

---

## 🚀 Instalación

1. Clona este repositorio o descarga el script:

```bash
git clone https://github.com/TU_USUARIO/nombre-del-repo.git
cd nombre-del-repo
chmod +x instalar_drive.sh
