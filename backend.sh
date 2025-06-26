#!/bin/bash
# Variables
USERID=$(id -u) # User id
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="/tmp/${TIMESTAMP}-${SCRIPT_NAME}.log"
REPO_URL="https://github.com/Niharika2211/backend-manual.git"
APP_DIR="/app"
# SERVICE_FILE="/etc/systemd/system/backend.service"
# CW_CONFIG_FILE="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

# Colors for terminal output
R="\e[31m"   # Red
G="\e[32m"   # Green
Y="\e[33m"   # Yellow
N="\e[0m"    # Reset

echo "Script started executing at: $TIMESTAMP"
echo "Log file: $LOG_FILE"

# Function to log command success or failure
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

# Check if the script is run as root
if [ $USERID -ne 0 ]; then
    echo -e "${R}Please run this script with sudo privileges${N}" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "${G}Here we go to installation${N}" | tee -a "$LOG_FILE"
fi

dnf update -y &>>"$LOG_FILE"
LOG "Updating the packages" $?

curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - &>>"$LOG_FILE"
LOG "Downloading Node.js setup script" $?

# Install required packages
dnf install git telnet nodejs amazon-cloudwatch-agent -y &>>"$LOG_FILE"
LOG "Installing git, telnet, Node.js 20, and CloudWatch Agent" $?

# Add 'expense' user if not exists
if ! id -u mini &>/dev/null; then
    useradd mini &>>"$LOG_FILE"
    LOG "Adding 'mini' user" $?
fi

# Clone backend repository if directory doesn't exist
if [ ! -d "$APP_DIR" ]; then
    mkdir "$APP_DIR" &>>"$LOG_FILE"
    LOG "Creating directory $APP_DIR" $?

    git clone "$REPO_URL" "$APP_DIR" &>>"$LOG_FILE"
    LOG "Cloning expense-backend repository to $APP_DIR" $?
else
    echo "Directory $APP_DIR already exists. Skipping cloning." | tee -a "$LOG_FILE"
fi

# Install dependencies for the backend
cd "$APP_DIR" && npm install &>>"$LOG_FILE"
LOG "Installing npm dependencies for the backend" $?
echo "Script execution completed successfully." | tee -a "$LOG_FILE"
