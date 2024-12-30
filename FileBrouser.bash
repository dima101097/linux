#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges."
    exit 1
fi

config="/etc/filebrowser/.filebrowser.yaml"
fb_service="/etc/systemd/system/filebrowser.service"

if type filebrowser >/dev/null 2>&1; then
    echo "FileBrowser is already installed."
    read -p "Do you want to reinstall it? (y/n): " a
    if [[ "$a" != "y" ]]; then
        echo "Operation aborted. FileBrowser will not be reinstalled."
        exit 0
    else
        echo "Installing FileBrowser..."
    fi
fi
if type curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
elif type wget >/dev/null 2>&1; then
    wget -qO- https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
else
    echo "Neither curl nor wget is installed. Please install one of them."
    exit 1
fi

if [ -d "/etc/filebrowser" ]; then
    echo "Directory /etc/filebrowser/ exists"
else
    echo "Create filebrowser directory"
    mkdir -p /etc/filebrowser/
fi

echo "Create filebrowser.yaml"
if [ -f "$config" ]; then
    echo "Warning: The file '$config' already exists. Its content will be overwritten."
    read -p "Do you want to continue? (y/n): " a
    if [[ "$a" != "y" ]]; then
        echo "Operation aborted."
        exit 0
    fi
fi

echo -e "port: 8080\naddress: 0.0.0.0\nroot: /path/to/your/file\ndatabase: /etc/filebrowser/filebrowser.db" > "$config"
echo "Creation successful."

echo "Create filebrowser.service"
if [ -f "$fb_service" ]; then
    echo "Warning: The file '$fb_service' already exists. Its content will be overwritten."
    read -p "Do you want to continue? (y/n): " a
    if [[ "$a" != "y" ]]; then
        echo "Operation aborted."
        exit 0
    fi
fi

echo -e "[Unit]\nDescription=File Browser Service\nAfter=network.target\n\n[Service]\nType=simple\nRestart=on-failure\nRestartSec=5s\nExecStart=filebrowser\n\n[Install]\nWantedBy=multi-user.target" > "$fb_service"
echo "Creation successful."

echo "Starting FileBrowser service..."
systemctl start filebrowser.service
echo "Enabling FileBrowser service to start on boot..."
systemctl enable filebrowser.service

echo "Script completed successfully. FileBrowser is now installed and running."
echo "Web ipAdress:8080"
echo "Login/Password: admin/admin" 
exit
