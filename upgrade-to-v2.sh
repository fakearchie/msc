#!/bin/bash

# 🎵 YouTube Download Pro v2.0 - Complete Upgrade Script
# This script upgrades your existing installation to the new modern interface

set -e

echo "🚀 Upgrading to YouTube Download Pro v2.0..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}"
    echo "=========================================="
    echo "🎵 YouTube Download Pro v2.0 Upgrade"
    echo "=========================================="
    echo -e "${NC}"
}

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

print_header

# Detect current user and setup
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

print_status "Detected user: $CURRENT_USER"

# Find project directory
POSSIBLE_DIRS=("$USER_HOME/spotify-clone" "$USER_HOME/msc" "./")
PROJECT_DIR=""

for dir in "${POSSIBLE_DIRS[@]}"; do
    if [[ -d "$dir" && -f "$dir/docker-compose.yml" ]]; then
        PROJECT_DIR="$dir"
        break
    fi
done

if [[ -z "$PROJECT_DIR" ]]; then
    print_error "Could not find existing installation. Running fresh install..."
    
    PROJECT_DIR="$USER_HOME/spotify-clone"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    git clone https://github.com/fakearchie/msc.git .
    print_success "Fresh installation completed"
else
    print_status "Found existing installation at: $PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

# Backup current installation
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
print_status "Creating backup: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"
if [[ -f "config/config.env" ]]; then
    cp config/config.env "$BACKUP_DIR/"
fi
if [[ -f "docker-compose.yml" ]]; then
    cp docker-compose.yml "$BACKUP_DIR/"
fi
print_success "Backup created"

# Stop existing services
print_status "Stopping existing services..."
docker-compose down 2>/dev/null || true
docker stop youtube_downloader navidrome 2>/dev/null || true
docker rm youtube_downloader navidrome 2>/dev/null || true
print_success "Services stopped"

# Update from GitHub
print_status "Updating code from GitHub..."
git stash 2>/dev/null || true
git pull origin main || {
    print_warning "Git pull failed, cloning fresh..."
    cd ..
    rm -rf "$PROJECT_DIR"
    git clone https://github.com/fakearchie/msc.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
}

# Restore config if it exists
if [[ -f "$BACKUP_DIR/config.env" ]]; then
    print_status "Restoring configuration..."
    cp "$BACKUP_DIR/config.env" config/config.env
    print_success "Configuration restored"
fi

# Create new config if none exists
if [[ ! -f "config/config.env" ]]; then
    print_status "Creating new configuration..."
    cp config/config.env.example config/config.env
    
    # Auto-detect server IP
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    # Update config with detected IP
    sed -i "s/YOUR_PI_IP/$SERVER_IP/g" config/config.env 2>/dev/null || true
    
    print_success "Configuration created with IP: $SERVER_IP"
fi

# Ensure directories exist
print_status "Setting up directories..."
sudo mkdir -p /music /downloads
sudo chown -R $CURRENT_USER:$CURRENT_USER /music /downloads 2>/dev/null || {
    # Fallback for systems without sudo or different permissions
    mkdir -p music downloads 2>/dev/null || true
}
print_success "Directories ready"

# Build and start new services
print_status "Building new services with modern interface..."
docker-compose build --no-cache web
docker-compose pull navidrome

print_status "Starting YouTube Download Pro v2.0..."
docker-compose up -d

# Wait for services
print_status "Waiting for services to initialize..."
sleep 15

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "All services are running!"
else
    print_warning "Some services may need more time to start"
fi

# Get server IP for final output
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

# Show final success message
echo ""
echo -e "${GREEN}🎉 UPGRADE COMPLETED SUCCESSFULLY! 🎉${NC}"
echo ""
echo "=========================================="
echo "🎵 YouTube Download Pro v2.0 is Ready!"
echo "=========================================="
echo ""
echo -e "${BLUE}🌐 Access Your Services:${NC}"
echo "   • 🎵 Navidrome: http://$SERVER_IP:4533"
echo "   • ⬇️ Download Manager: http://$SERVER_IP:8080"
echo "   • 🚀 Extension Install: http://$SERVER_IP:8080/install-extension"
echo ""
echo -e "${PURPLE}✨ New Features in v2.0:${NC}"
echo "   ✅ Modern dark theme with animations"
echo "   ✅ Mobile-responsive design"
echo "   ✅ Auto-paste from clipboard"
echo "   ✅ Keyboard shortcuts (Enter/Escape)"
echo "   ✅ Smart notifications"
echo "   ✅ One-click browser extension install"
echo "   ✅ Bookmarklet option (no extension needed)"
echo "   ✅ Auto-update system"
echo ""
echo -e "${YELLOW}📱 Next Steps:${NC}"
echo "   1. Visit: http://$SERVER_IP:8080/install-extension"
echo "   2. Install the browser extension"
echo "   3. Go to Navidrome and look for the floating YouTube button!"
echo "   4. Enjoy downloading music with the beautiful new interface!"
echo ""
echo -e "${GREEN}🔄 Maintenance:${NC}"
echo "   • Update anytime: ./update.sh"
echo "   • View logs: docker-compose logs"
echo "   • Restart: docker-compose restart"
echo ""
echo "Welcome to the future of music downloading! 🚀✨"
echo "=========================================="

# Set up auto-update if not exists
if ! crontab -l 2>/dev/null | grep -q "git pull origin main"; then
    print_status "Setting up auto-updates..."
    (crontab -l 2>/dev/null; echo "0 2 * * * cd $PROJECT_DIR && git pull origin main && docker-compose restart youtube_downloader") | crontab -
    print_success "Auto-updates enabled (daily at 2 AM)"
fi

# Create update script for easy manual updates
cat > update.sh << EOF
#!/bin/bash
echo "🔄 Updating YouTube Download Pro..."
cd "\$(dirname "\$0")"
git pull origin main
docker-compose restart youtube_downloader
echo "✅ Update completed!"
echo "🌐 Access: http://$SERVER_IP:8080/install-extension"
EOF

chmod +x update.sh
print_success "Update script created: ./update.sh"

echo ""
echo -e "${GREEN}Upgrade completed successfully! Enjoy your new modern music server! 🎵${NC}"
