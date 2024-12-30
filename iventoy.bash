#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges."
    exit 1
fi

if type curl >/dev/null 2>&1; then
    release=$(curl -s https://api.github.com/repos/ventoy/pxe/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    curl -LO https://github.com/ventoy/PXE/releases/download/v${release}/iventoy-${release}-linux-free.tar.gz
elif type wget >/dev/null 2>&1; then
    release=$(wget -qO- https://api.github.com/repos/ventoy/pxe/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    wget -q https://github.com/ventoy/PXE/releases/download/v${release}/iventoy-${release}-linux-free.tar.gz
else
    echo "Neither curl nor wget is installed. Please install one of them."
    exit 1
fi

if [ -d "/opt/iventoy" ]; then
    echo "Directory /opt/iventoy exists"
else
    echo "Create filebrowser directory"
    mkdir -p /opt/iventoy/{data,iso}
fi
tar -C /tmp -xzf iventoy*.tar.gz
mv /tmp/iventoy*/* /opt/iventoy/
rm -rf iventoy*.tar.gz
echo "Installed iVentoy"

echo "Creating Service"
cat <<EOF >/etc/systemd/system/iventoy.service
[Unit]
Description=iVentoy PXE Booter
Documentation=https://www.iventoy.com
Wants=network-online.target
[Service]
Type=forking
Environment=IVENTOY_API_ALL=1
Environment=IVENTOY_AUTO_RUN=1
Environment=LIBRARY_PATH=/opt/iventoy/lib/lin64
Environment=LD_LIBRARY_PATH=/opt/iventoy/lib/lin64
ExecStart=sh ./iventoy.sh -R start
WorkingDirectory=/opt/iventoy
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

echo "Starting iVentoy service..."
systemctl start iventoy.service
echo "Enabling iVentoy service to start on boot..."
systemctl enable iventoy.service

echo "Script completed successfully. iventoy.service is now installed and running."
echo "Web ipAdress:26000"
exit
