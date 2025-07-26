#!/bin/bash

# Music Server Startup Script
# Use this to start/stop/restart the entire music server

set -e

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

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

# Function to check if Docker is running
check_docker() {
    if ! command -v docker > /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Start it with: sudo systemctl start docker"
        exit 1
    fi
}

# Function to check configuration
check_config() {
    if [ ! -f "config/config.env" ]; then
        print_warning "config.env not found. Creating from example..."
        if [ -f "config/config.env.example" ]; then
            cp config/config.env.example config/config.env
            print_warning "Please edit config/config.env before continuing"
            print_warning "At minimum, change the ADMIN_PASSWORD"
            exit 1
        else
            print_error "No configuration files found"
            exit 1
        fi
    fi
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p logs cache queue
    mkdir -p /home/pi/music/{downloads,library}
    sudo chown -R pi:pi /home/pi/music 2>/dev/null || {
        print_warning "Could not change ownership of music directory"
    }
}

# Function to make scripts executable
make_scripts_executable() {
    print_status "Making scripts executable..."
    chmod +x scripts/*.sh
}

# Function to start services
start_services() {
    print_header "🚀 Starting Music Server Services"
    
    check_docker
    check_config
    create_directories
    make_scripts_executable
    
    print_status "Starting Docker containers..."
    docker-compose up -d
    
    print_status "Waiting for services to start..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_status "Services started successfully!"
        
        # Get local IP
        LOCAL_IP=$(hostname -I | awk '{print $1}')
        
        echo ""
        print_header "🎵 Your Music Server is Ready!"
        echo ""
        echo -e "${GREEN}Access Points:${NC}"
        echo "• Music Player: http://$LOCAL_IP:4533"
        echo "• Download Interface: http://$LOCAL_IP:8080"
        echo "• Combined Interface: http://$LOCAL_IP"
        echo ""
        echo -e "${YELLOW}Default Login:${NC}"
        echo "• Username: admin"
        echo "• Password: (check config/config.env)"
        echo ""
        echo -e "${BLUE}Next Steps:${NC}"
        echo "1. Open the music player and create your account"
        echo "2. Use the download interface to add music"
        echo "3. Install a mobile app (DSub, Substreamer, etc.)"
        echo "4. Configure monitoring in config/config.env"
        
    else
        print_error "Some services failed to start"
        docker-compose ps
        echo ""
        print_error "Check logs with: docker-compose logs"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    print_header "🛑 Stopping Music Server Services"
    
    print_status "Stopping Docker containers..."
    docker-compose down
    
    print_status "Services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_header "🔄 Restarting Music Server Services"
    
    print_status "Stopping services..."
    docker-compose down
    
    print_status "Starting services..."
    docker-compose up -d
    
    print_status "Services restarted successfully!"
}

# Function to show status
show_status() {
    print_header "📊 Music Server Status"
    
    echo ""
    echo -e "${GREEN}Docker Containers:${NC}"
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}System Resources:${NC}"
    echo "Memory Usage:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h /home/pi/music 2>/dev/null || df -h /home/pi
    
    echo ""
    echo -e "${GREEN}Recent Activity:${NC}"
    if [ -f logs/downloader.log ]; then
        echo "Last 5 download log entries:"
        tail -5 logs/downloader.log
    fi
    
    echo ""
    echo -e "${GREEN}Music Library:${NC}"
    local music_count=$(find /home/pi/music -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" -o -name "*.flac" \) 2>/dev/null | wc -l)
    echo "Total music files: $music_count"
}

# Function to show logs
show_logs() {
    print_header "📜 Recent Logs"
    
    local service="$1"
    
    if [ -n "$service" ]; then
        print_status "Showing logs for: $service"
        docker-compose logs --tail=50 "$service"
    else
        print_status "Showing logs for all services"
        docker-compose logs --tail=20
    fi
}

# Function to update system
update_system() {
    print_header "🔄 Updating Music Server"
    
    print_status "Pulling latest Docker images..."
    docker-compose pull
    
    print_status "Updating yt-dlp..."
    sudo yt-dlp -U || print_warning "Could not update yt-dlp"
    
    print_status "Restarting services with new images..."
    docker-compose down
    docker-compose up -d
    
    print_status "Update completed!"
}

# Function to run health check
health_check() {
    print_header "🔍 Health Check"
    
    if [ -f scripts/health_check.sh ]; then
        scripts/health_check.sh
    else
        print_error "Health check script not found"
        exit 1
    fi
}

# Function to download music
download_music() {
    local url="$1"
    
    if [ -z "$url" ]; then
        print_error "Please provide a YouTube URL"
        echo "Usage: $0 download <youtube_url>"
        exit 1
    fi
    
    print_header "⬇️ Downloading Music"
    
    if [ -f scripts/download_music.sh ]; then
        scripts/download_music.sh "$url"
    else
        print_error "Download script not found"
        exit 1
    fi
}

# Main function
main() {
    local action="${1:-help}"
    
    case "$action" in
        "start"|"up")
            start_services
            ;;
        "stop"|"down")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status"|"ps")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "update")
            update_system
            ;;
        "health")
            health_check
            ;;
        "download")
            download_music "$2"
            ;;
        "help"|*)
            print_header "🎵 Music Server Control Script"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  start, up      - Start all services"
            echo "  stop, down     - Stop all services"
            echo "  restart        - Restart all services"
            echo "  status, ps     - Show service status"
            echo "  logs [service] - Show logs (optional: specific service)"
            echo "  update         - Update images and restart"
            echo "  health         - Run health check"
            echo "  download <url> - Download music from URL"
            echo "  help           - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 start"
            echo "  $0 logs navidrome"
            echo "  $0 download 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
            echo ""
            ;;
    esac
}

# Run main function with all arguments
main "$@"
