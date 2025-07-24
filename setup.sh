#!/bin/bash

set -e

RCLONE_VERSION="v1.70.2"
REMOTE_NAME="mi_drive"
INSTALL_DIR="/usr/local/bin"
USER_HOME="/home/$USER"
FISH_CONFIG="$USER_HOME/.config/fish/config.fish"

# Instalar Rclone si no existe o no es la versión correcta
if ! command -v rclone &> /dev/null || [[ "$(rclone --version | head -n1 | awk '{print $2}')" != "$RCLONE_VERSION" ]]; then
    echo "Instalando Rclone $RCLONE_VERSION..."
    curl -LO "https://downloads.rclone.org/$RCLONE_VERSION/rclone-$RCLONE_VERSION-linux-amd64.zip"
    unzip -o "rclone-$RCLONE_VERSION-linux-amd64.zip"
    sudo cp "rclone-$RCLONE_VERSION-linux-amd64/rclone" "$INSTALL_DIR"
    sudo chmod 755 "$INSTALL_DIR/rclone"
    rm -rf "rclone-$RCLONE_VERSION-linux-amd64" "rclone-$RCLONE_VERSION-linux-amd64.zip"
else
    echo "✅ Rclone $RCLONE_VERSION ya está instalado."
fi

# Pedir enlace de carpeta
read -p "Pega el enlace de la carpeta de Google Drive que quieres sincronizar: " LINK

# Extraer solo la última parte después de la última barra /
FOLDER_ID="${LINK##*/}"

# Preguntar nombre del remoto
read -p "¿Cómo quieres llamar al remote? [Drive]: " REMOTE_NAME
REMOTE_NAME="${REMOTE_NAME:-Drive}"

# Preguntar nombre de carpeta local (opcional)
read -p "¿Cómo quieres llamar a la carpeta local donde se guardarán los archivos? [drive]: " LOCAL_FOLDER
LOCAL_FOLDER="${LOCAL_FOLDER:-drive}"  # Si está vacío, usar "drive" como predeterminado
echo "La carpeta se creara en /home/$USER"

# Verificar si el remote ya existe
if rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo "Remote '$REMOTE_NAME' ya existe, usándolo."
else
    echo "Creando remote '$REMOTE_NAME'..."
    rclone config create "$REMOTE_NAME" drive scope=drive root_folder_id="$FOLDER_ID"
    echo "Remote '$REMOTE_NAME' creado."
fi

# Detectar shell predeterminada
USER_SHELL=$(basename "$SHELL")

# Definir archivo de configuración según la shell
case "$USER_SHELL" in
  zsh)
    SHELL_CONFIG="$HOME/.zshrc"
    ;;
  bash)
    SHELL_CONFIG="$HOME/.bashrc"
    ;;
  fish)
    SHELL_CONFIG="$HOME/.config/fish/config.fish"
    ;;
  *)
    echo "⚠️ Shell no reconocida: $USER_SHELL. No se añadirán alias automáticamente."
    SHELL_CONFIG=""
    ;;
esac

# Añadir alias si se detectó una shell compatible
if [[ -n "$SHELL_CONFIG" ]]; then
  # Solo añadir si no están ya definidos
  if ! grep -q "alias uploadrive=" "$SHELL_CONFIG"; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Alias para Rclone y Google Drive" >> "$SHELL_CONFIG"
    echo "alias uploadrive='rclone sync ~/${LOCAL_FOLDER} ${REMOTE_NAME}:/ --progress'" >> "$SHELL_CONFIG"
    echo "alias downloadrive='rclone sync ${REMOTE_NAME}:/ ~/${LOCAL_FOLDER} --progress'" >> "$SHELL_CONFIG"
    echo "Alias añadidos a $SHELL_CONFIG"
  else
    echo "Alias ya definidos en $SHELL_CONFIG, no se duplicarán."
  fi
else
  echo "No se pudieron añadir alias automáticamente. Añádelos manualmente si lo deseas."
fi

# rclone sync mi-drive:/ ~/drive --progress         -- Bajar
# rclone sync ~/drive mi-drive:/ --progress         -- Subir