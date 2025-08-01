#!/bin/bash

# Music Server Installation Script
# Simple installation for Raspberry Pi

set -e

echo "🎵 Installing Music Server..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker and dependencies
echo "🔧 Installing Docker..."
sudo apt install -y docker.io docker-compose python3-pip git curl

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Create music directory
mkdir -p /home/pi/music
sudo chown -R $USER:$USER /home/pi/music

# Setup configuration
if [ ! -f "config/config.env" ]; then
    echo "📋 Creating config file..."
    cp config/config.env.example config/config.env
fi

# Make scripts executable
chmod +x scripts/*.sh

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Get IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Installation complete!"
echo ""
echo "🌐 Access at:"
echo "   Music Player: http://$PI_IP:4533"
echo "   Downloads:    http://$PI_IP:8080"
echo ""
echo "📱 Mobile Apps: Play:Sub (iOS), DSub (Android)"
echo "🔑 Login: admin / check config/config.env"
echo ""
echo "⚠️  Logout and login again to activate Docker permissions"
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_header "🎵 Raspberry Pi Music Server - One-Command Installer"
echo "============================================================"
echo "This will install a complete self-hosted Spotify alternative"
echo "with automatic YouTube downloads and mobile app support."
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_warning "This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if running as pi user
if [ "$USER" != "pi" ]; then
    print_error "Please run as the 'pi' user, not root"
    exit 1
fi

print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing git..."
sudo apt install -y git

print_status "Cloning project from GitHub..."
if [ -d "/home/pi/spotify-clone" ]; then
    print_warning "Directory /home/pi/spotify-clone already exists"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf /home/pi/spotify-clone
    else
        print_error "Installation cancelled"
        exit 1
    fi
fi

git clone https://github.com/fakearchie/msc.git /home/pi/spotify-clone
cd /home/pi/spotify-clone

print_status "Making scripts executable..."
chmod +x scripts/*.sh

print_status "Running main installation script..."
sudo ./scripts/install.sh

print_status "Setting up initial configuration..."
if [ ! -f config/config.env ]; then
    cp config/config.env.example config/config.env
    print_warning "Configuration created at config/config.env"
    print_warning "IMPORTANT: Edit this file to change the admin password!"
fi

print_header "🎉 Installation Complete!"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Reboot your Pi: ${YELLOW}sudo reboot${NC}"
echo "2. Edit configuration: ${YELLOW}nano /home/pi/spotify-clone/config/config.env${NC}"
echo "3. Start services: ${YELLOW}cd /home/pi/spotify-clone && ./scripts/music-server.sh start${NC}"
echo ""
echo -e "${BLUE}Quick start after reboot:${NC}"
echo "cd /home/pi/spotify-clone"
echo "nano config/config.env  # Change admin password"
echo "./scripts/music-server.sh start"
echo ""
echo -e "${GREEN}Access your server at:${NC}"
echo "• Music Player: http://$(hostname -I | awk '{print $1}'):4533"
echo "• Downloads: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "• Setup Guide: /home/pi/spotify-clone/SETUP_GUIDE.md"
echo "• Quick Reference: /home/pi/spotify-clone/QUICK_REFERENCE.md"
echo "• GitHub: https://github.com/fakearchie/msc"
