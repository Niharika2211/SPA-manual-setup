#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
NODE_EXPORTER_VERSION="1.9.1"
NODE_EXPORTER_USER="ec2-user"
NODE_EXPORTER_DIR="/home/${NODE_EXPORTER_USER}/node_exporter"
LOG_FILE="/tmp/${TIMESTAMP}-${SCRIPT_NAME}.log"

# Colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

echo "Started at: $TIMESTAMP"
echo "Log: $LOG_FILE"

LOG() {
    local MESSAGE="$1"
    local STATUS="$2"
    if [ "$STATUS" -eq 0 ]; then
        echo -e "$MESSAGE ..... ${G}Success${N}" | tee -a "$LOG_FILE"
    else
        echo -e "$MESSAGE ..... ${R}Failed${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Check root
if [ "$USERID" -ne 0 ]; then
    echo -e "${R}Run with sudo/root${N}" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "${G}Starting frontend setup...${N}" | tee -a "$LOG_FILE"

# Install Node.js and Nginx
dnf install -y nginx git &>>"$LOG_FILE"
LOG "Installing Nginx and Git" $?

curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - &>>"$LOG_FILE"
dnf install -y nodejs &>>"$LOG_FILE"
LOG "Installing Node.js" $?

# Enable and start Nginx
systemctl enable nginx &>>"$LOG_FILE"
LOG "Enabling Nginx" $?
systemctl start nginx &>>"$LOG_FILE"
LOG "Starting Nginx" $?

# Clear existing html
rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
LOG "Clearing Nginx HTML folder" $?

# Clone and build frontend
cd /tmp
git clone https://github.com/Niharika2211/frontend-manual.git &>>"$LOG_FILE"
LOG "Cloning frontend repo" $?

cd frontend-app
npm install &>>"$LOG_FILE"
LOG "Running npm install" $?

npm run build &>>"$LOG_FILE"
LOG "Running npm build" $?

# Copy built files to nginx
cp -r dist/* /usr/share/nginx/html/ &>>"$LOG_FILE"
LOG "Copying build to /usr/share/nginx/html" $?

# Node Exporter Setup
cd /home/$NODE_EXPORTER_USER || exit 1
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz &>>"$LOG_FILE"
LOG "Downloading Node Exporter v${NODE_EXPORTER_VERSION}" $?

tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz &>>"$LOG_FILE"
mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64 node_exporter &>>"$LOG_FILE"
rm -f node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
LOG "Extracted Node Exporter" $?

# Create systemd service for Node Exporter
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=${NODE_EXPORTER_USER}
ExecStart=${NODE_EXPORTER_DIR}/node_exporter
Restart=on-failure

[Install]
WantedBy=default.target
EOF

LOG "Node Exporter systemd service file created" $?

# Reload and start Node Exporter service
systemctl daemon-reexec &>>"$LOG_FILE"
systemctl daemon-reload &>>"$LOG_FILE"
systemctl enable node_exporter &>>"$LOG_FILE"
systemctl start node_exporter &>>"$LOG_FILE"
LOG "Node Exporter service started" $?


echo -e "${G}Frontend deployment complete.${N}" | tee -a "$LOG_FILE"
