#!/bin/bash
set -e

APP_DIR="/app"
SERVICE_FILE="/etc/systemd/system/backend.service"
SECRET_NAME="pro-man/spa/db-creds"

# Install necessary tools
echo "Installing awscli and jq"
dnf install -y awscli jq

# Fetch Secrets from Secrets Manager
echo "Fectching Secrets from SecretsManager"
SECRETS=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text)
DB_USER=$(echo "$SECRETS" | jq -r .DB_USER)
DB_PASSWORD=$(echo "$SECRETS" | jq -r .DB_PASSWORD)

# Fetch Configuration from SSM Parameter Store
echo "Fetching non-sensitive data from ParameterStore"
DB_HOST=$(aws ssm get-parameter --name "/pro-man/DB_HOST" --with-decryption --query "Parameter.Value" --output text)
DB_NAME=$(aws ssm get-parameter --name "/pro-man/DB_NAME" --with-decryption --query "Parameter.Value" --output text)
REDIS_HOST=$(aws ssm get-parameter --name "/pro-man/REDIS_HOST" --with-decryption --query "Parameter.Value" --output text)


# Generate systemd service file
echo "Generate service file for backend"
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Backend Service

[Service]
User=expense
Environment="DB_HOST=${DB_HOST}"
Environment="DB_USER=${DB_USER}"
Environment="DB_PASSWORD=${DB_PASSWORD}" 
Environment="DB_NAME=${DB_NAME}"
Environment="REDIS_HOST=${REDIS_HOST}"
ExecStart=/usr/bin/node ${APP_DIR}/server.js
SyslogIdentifier=backend
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start service
echo "Restart enable and start backend"
systemctl daemon-reload
systemctl enable backend
systemctl start backend
