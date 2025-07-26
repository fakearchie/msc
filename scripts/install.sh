#!/bin/bash

# Raspberry Pi 5 Music Server Installation Script
# This script sets up everything needed for your self-hosted Spotify alternative

set -e

echo "🎵 Setting up Self-Hosted Music Server on Raspberry Pi 5..."
echo "==============================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Please don't run this script as root. Run as the pi user."
    exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    ffmpeg \
    docker.io \
    docker-compose \
    nginx \
    cron \
    htop \
    tree

# Install yt-dlp
print_status "Installing yt-dlp..."
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

# Add user to docker group
print_status "Adding user to docker group..."
sudo usermod -aG docker $USER

# Create music directory structure
print_status "Creating music directory structure..."
mkdir -p /home/pi/music/{downloads,library} || {
    print_warning "Music directory already exists or permission issue"
}
mkdir -p /home/pi/spotify-clone/{logs,config,web,scripts} || {
    print_warning "Project directories already exist"
}

# Set proper permissions
if [ -d "/home/pi/music" ]; then
    sudo chown -R pi:pi /home/pi/music 2>/dev/null || {
        print_warning "Could not change ownership of music directory"
    }
    chmod -R 755 /home/pi/music 2>/dev/null || {
        print_warning "Could not set permissions on music directory"
    }
fi

# Create systemd service for automatic scanning
print_status "Creating systemd services..."
sudo tee /etc/systemd/system/music-downloader.service > /dev/null <<EOF
[Unit]
Description=Music Downloader Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/spotify-clone
ExecStart=/home/pi/spotify-clone/scripts/download_monitor.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Create timer for periodic checks
sudo tee /etc/systemd/system/music-downloader.timer > /dev/null <<EOF
[Unit]
Description=Run music downloader every hour
Requires=music-downloader.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start services
print_status "Enabling systemd services..."
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

# Test yt-dlp installation
print_status "Testing yt-dlp installation..."
if yt-dlp --version > /dev/null 2>&1; then
    print_status "yt-dlp installed successfully: $(yt-dlp --version)"
else
    print_error "yt-dlp installation failed"
    exit 1
fi

# Create initial configuration
print_status "Setting up initial configuration..."
if [ ! -f "/home/pi/spotify-clone/config/config.env" ]; then
    cp /home/pi/spotify-clone/config/config.env.example /home/pi/spotify-clone/config/config.env 2>/dev/null || true
fi

# Set up logrotate for log management
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/music-server > /dev/null <<EOF
/home/pi/spotify-clone/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 pi pi
}
EOF

# Install Python requirements for web interface
print_status "Installing Python requirements..."
pip3 install --user flask requests pyyaml python-dotenv

print_status "Installation completed successfully!"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Reboot your Pi: sudo reboot"
echo "2. Edit configuration: nano /home/pi/spotify-clone/config/config.env"
echo "3. Start services: cd /home/pi/spotify-clone && docker-compose up -d"
echo "4. Access Navidrome at: http://$(hostname -I | awk '{print $1}'):4533"
echo "5. Access download interface at: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "- Change the default admin password in config.env"
echo "- Add your YouTube playlists to monitor"
echo "- Configure your router for external access if needed"
