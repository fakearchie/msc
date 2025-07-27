#!/bin/bash

# 🚀 YouTube Download Pro - One-Time Setup Script
# This script sets up auto-update mechanisms so you never need to reinstall manually

set -e

echo "🎵 Setting up YouTube Download Pro with Auto-Updates..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
if [[ $(uname -m) == "aarch64" || $(uname -m) == "armv7l" ]]; then
    print_status "Detected Raspberry Pi architecture"
    IS_PI=true
else
    print_status "Running on x86_64 architecture"
    IS_PI=false
fi

# Detect user (admin vs pi)
if id "admin" &>/dev/null; then
    USER_HOME="/home/admin"
    CURRENT_USER="admin"
elif id "pi" &>/dev/null; then
    USER_HOME="/home/pi"
    CURRENT_USER="pi"
else
    USER_HOME="$HOME"
    CURRENT_USER=$(whoami)
fi

print_status "Using user: $CURRENT_USER, home: $USER_HOME"

# Project directory
PROJECT_DIR="$USER_HOME/spotify-clone"

# Create project directory if it doesn't exist
if [[ ! -d "$PROJECT_DIR" ]]; then
    print_status "Creating project directory..."
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Initialize as git repo if not already
    if [[ ! -d ".git" ]]; then
        git init
        git remote add origin https://github.com/fakearchie/msc.git
        print_success "Git repository initialized"
    fi
else
    cd "$PROJECT_DIR"
    print_status "Using existing project directory"
fi

# Update from GitHub
print_status "Updating from GitHub..."
if git remote get-url origin &>/dev/null; then
    git pull origin main 2>/dev/null || {
        print_warning "Git pull failed, trying to reset..."
        git fetch origin
        git reset --hard origin/main
    }
else
    print_warning "No git remote found, cloning fresh..."
    cd ..
    rm -rf "$PROJECT_DIR"
    git clone https://github.com/fakearchie/msc.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

print_success "Code updated from GitHub"

# Set up auto-update cron job
print_status "Setting up auto-update cron job..."

CRON_JOB="0 2 * * * cd $PROJECT_DIR && git pull origin main && docker-compose restart youtube_downloader"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "git pull origin main"; then
    print_warning "Auto-update cron job already exists"
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    print_success "Auto-update cron job added (runs daily at 2 AM)"
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $CURRENT_USER
    rm get-docker.sh
    print_success "Docker installed"
else
    print_status "Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    if [[ "$IS_PI" == true ]]; then
        # For Raspberry Pi
        sudo apt update
        sudo apt install -y docker-compose
    else
        # For x86_64
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    print_success "Docker Compose installed"
else
    print_status "Docker Compose already installed"
fi

# Set up environment configuration
print_status "Setting up environment configuration..."

if [[ ! -f "config/config.env" ]]; then
    if [[ -f "config/config.env.example" ]]; then
        cp config/config.env.example config/config.env
        print_success "Environment config created from example"
    else
        # Create basic config
        mkdir -p config
        cat > config/config.env << EOF
# Music Server Configuration
MUSIC_DIR=/music
DOWNLOAD_DIR=/downloads

# Navidrome Configuration
NAVIDROME_USER=admin
NAVIDROME_PASS=password

# Server Configuration
SERVER_IP=$(hostname -I | awk '{print $1}')
YOUTUBE_DOWNLOADER_PORT=8080
NAVIDROME_PORT=4533
EOF
        print_success "Basic environment config created"
    fi
else
    print_status "Environment config already exists"
fi

# Create music and download directories
print_status "Creating music directories..."
sudo mkdir -p /music /downloads
sudo chown -R $CURRENT_USER:$CURRENT_USER /music /downloads
print_success "Music directories created"

# Build and start services
print_status "Building and starting services..."

# Stop any existing containers
docker-compose down 2>/dev/null || true

# Remove any conflicting containers
docker rm -f youtube_downloader navidrome 2>/dev/null || true

# Pull latest images and build
docker-compose pull
docker-compose build --no-cache

# Start services
docker-compose up -d

print_success "Services started successfully"

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check service status
if docker-compose ps | grep -q "Up"; then
    print_success "All services are running"
else
    print_error "Some services failed to start"
    docker-compose logs
fi

# Set up webhook for GitHub auto-updates (optional)
print_status "Setting up GitHub webhook endpoint..."

cat > scripts/webhook-update.sh << 'EOF'
#!/bin/bash
# GitHub webhook handler for auto-updates

cd /home/admin/spotify-clone || cd /home/pi/spotify-clone || exit 1

echo "$(date): Received webhook update" >> /var/log/music-server-update.log

# Pull latest changes
git pull origin main

# Restart only if docker-compose.yml or web/ changed
if git diff --name-only HEAD~1 | grep -E "(docker-compose\.yml|web/|navidrome-integration/)"; then
    echo "$(date): Restarting services due to changes" >> /var/log/music-server-update.log
    docker-compose restart youtube_downloader
fi

echo "$(date): Update completed" >> /var/log/music-server-update.log
EOF

chmod +x scripts/webhook-update.sh
print_success "Webhook update script created"

# Create easy update script for manual updates
cat > update.sh << 'EOF'
#!/bin/bash
# Manual update script

echo "🔄 Updating YouTube Download Pro..."

cd "$(dirname "$0")"

# Pull latest changes
git pull origin main

# Restart services
docker-compose restart youtube_downloader

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "✅ Update completed!"
echo ""
echo "🎵 Access your services:"
echo "   • Navidrome: http://$SERVER_IP:4533"
echo "   • Download Manager: http://$SERVER_IP:8080"
echo "   • Extension Install: http://$SERVER_IP:8080/install-extension"
echo ""
echo "📱 To install the browser extension:"
echo "   1. Visit: http://$SERVER_IP:8080/install-extension"
echo "   2. Follow the instructions"
echo "   3. Enjoy seamless YouTube downloading!"
EOF

chmod +x update.sh
print_success "Manual update script created"

# Get server IP for final output
SERVER_IP=$(hostname -I | awk '{print $1}')

print_success "🎉 YouTube Download Pro setup completed!"
echo ""
echo "==========================================⭐"
echo "🎵 Your Modern Music Server is Ready! 🎵"
echo "=========================================="
echo ""
echo "🌐 Access URLs:"
echo "   • Navidrome: http://$SERVER_IP:4533"
echo "   • Download Manager: http://$SERVER_IP:8080"
echo "   • Extension Install: http://$SERVER_IP:8080/install-extension"
echo ""
echo "📱 Browser Extension Installation:"
echo "   1. Visit: http://$SERVER_IP:8080/install-extension"
echo "   2. Install Tampermonkey"
echo "   3. Click 'Install Extension'"
echo "   4. Visit Navidrome and enjoy the floating YouTube button!"
echo ""
echo "🔄 Auto-Update Features:"
echo "   ✅ Daily auto-updates from GitHub (2 AM)"
echo "   ✅ Manual update: ./update.sh"
echo "   ✅ Extension auto-updates via GitHub"
echo "   ✅ No more manual reinstallation needed!"
echo ""
echo "🎨 New Features:"
echo "   ✅ Modern dark theme with animations"
echo "   ✅ Auto-paste from clipboard"
echo "   ✅ Keyboard shortcuts (Enter/Escape)"
echo "   ✅ Mobile-responsive design"
echo "   ✅ Smart notifications"
echo "   ✅ Dashboard integration"
echo ""
echo "🔧 Maintenance:"
echo "   • View logs: docker-compose logs"
echo "   • Restart: docker-compose restart"
echo "   • Update: ./update.sh"
echo ""
echo "🆘 Support:"
echo "   • GitHub: https://github.com/fakearchie/msc"
echo "   • Issues: Create an issue on GitHub"
echo ""
echo "Welcome to the future of music downloading! 🚀✨"
echo "=========================================="
