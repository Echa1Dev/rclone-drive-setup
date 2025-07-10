#!/bin/bash

set -e

RCLONE_VERSION="v1.70.2"
RCLONE_ZIP="rclone-$RCLONE_VERSION-linux-amd64.zip"
RCLONE_URL="https://downloads.rclone.org/$RCLONE_VERSION/$RCLONE_ZIP"
INSTALL_DIR="/usr/local/bin"

echo "📦 Instalando Rclone v$RCLONE_VERSION..."

# Verificar si Rclone está instalado y es la versión correcta
if command -v rclone &> /dev/null; then
    INSTALLED_VERSION=$(rclone --version | head -n1 | awk '{print $2}')
    if [[ "$INSTALLED_VERSION" == "$RCLONE_VERSION" ]]; then
        echo "✅ Rclone v$RCLONE_VERSION ya está instalado."
    else
        echo "🔁 Rclone encontrado, pero no es la versión $RCLONE_VERSION. Reinstalando..."
        sudo rm -f "$INSTALL_DIR/rclone"
        NEED_INSTALL=true
    fi
else
    echo "⬇️ Rclone no está instalado. Instalando..."
    NEED_INSTALL=true
fi

# Instalar Rclone si es necesario
if [[ "$NEED_INSTALL" == true ]]; then
    curl -LO "$RCLONE_URL"
    unzip -o "rclone-${RCLONE_VERSION}-linux-amd64.zip"
    cd "rclone-${RCLONE_VERSION}-linux-amd64"
    sudo cp rclone "$INSTALL_DIR"
    sudo chown root:root "$INSTALL_DIR/rclone"
    sudo chmod 755 "$INSTALL_DIR/rclone"
    cd ..
    rm -rf "rclone-${RCLONE_VERSION}-linux-amd64" "rclone-${RCLONE_VERSION}-linux-amd64.zip"
    echo "✅ Rclone v$RCLONE_VERSION instalado correctamente."
fi

# Solicitar enlace de carpeta de Google Drive
read -p "📎 Pega el enlace de la carpeta de Google Drive: " LINK

# Extraer el ID de la carpeta
FOLDER_ID=$(echo "$LINK" | grep -oE '[-\w]{25,}')

if [[ -z "$FOLDER_ID" ]]; then
    echo "❌ No se pudo extraer el ID de la carpeta. Asegúrate de que el enlace sea válido."
    exit 1
fi

echo "📁 ID de la carpeta detectado: $FOLDER_ID"

# Comprobar si el remote ya existe
if rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo "⚠️ Ya existe un remote llamado '${REMOTE_NAME}'. Usándolo."
else
    echo "⚙️ Creando configuración automática de Rclone..."
    rclone config create "$REMOTE_NAME" drive scope=drive root_folder_id="$FOLDER_ID"
    echo "✅ Remote '$REMOTE_NAME' creado correctamente."
fi

# Crear scripts de sincronización
mkdir -p "$USER_HOME/scripts"

cat <<EOF > "$USER_HOME/scripts/subirdrive"
#!/bin/bash
rclone sync ~/Drive ${REMOTE_NAME}:/ --progress
EOF

cat <<EOF > "$USER_HOME/scripts/bajardrive"
#!/bin/bash
rclone sync ${REMOTE_NAME}:/ ~/Drive --progress
EOF

chmod +x "$USER_HOME/scripts/subirdrive" "$USER_HOME/scripts/bajardrive"

# Copiar scripts al home
cp "$USER_HOME/scripts/subirdrive" "$USER_HOME/subirdrive"
cp "$USER_HOME/scripts/bajardrive" "$USER_HOME/bajardrive"

chmod +x "$USER_HOME/subirdrive" "$USER_HOME/bajardrive"

# Añadir alias a Fish
echo "" >> "$FISH_CONFIG"
echo "# Aliases para Drive (rclone)" >> "$FISH_CONFIG"
echo "alias subirdrive='/home/$USER/subirdrive'" >> "$FISH_CONFIG"
echo "alias bajardrive='/home/$USER/bajardrive'" >> "$FISH_CONFIG"

echo "✅ Alias añadidos a Fish."

# Mensaje final
echo -e "\n🎉 Todo listo, Javi. Ahora puedes usar:"
echo "   👉 subirdrive  # Para subir tu carpeta ~/Drive a Google Drive"
echo "   👉 bajardrive  # Para bajarla desde Google Drive"
echo -e "\n🌐 La carpeta remota apunta a: https://drive.google.com/drive/folders/$FOLDER_ID"