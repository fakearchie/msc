#!/bin/bash

#
# YouTube Music Downloader Script
# Downloads music from YouTube URLs and organizes them
#

set -e

# Configuration
DOWNLOAD_DIR="/home/pi/music"
QUALITY="${2:-best}"
FORMAT="${3:-mp3}"
LOG_FILE="/tmp/download.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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

# Function to validate YouTube URL
validate_url() {
    local url="$1"
    if [[ $url =~ ^https?://(www\.)?(youtube\.com|youtu\.be|music\.youtube\.com) ]]; then
        return 0
    else
        print_error "Invalid YouTube URL: $url"
        return 1
    fi
}

# Function to download video/playlist
download_content() {
    local url="$1"
    local output_template="$DOWNLOAD_DIR/%(uploader)s/%(title)s.%(ext)s"
    
    print_status "Starting download..."
    print_status "URL: $url"
    print_status "Quality: $QUALITY | Format: $FORMAT"
    print_status "Output: $DOWNLOAD_DIR"
    echo
    
    # Execute yt-dlp with progress
    yt-dlp \
        --extract-audio \
        --audio-format "$FORMAT" \
        --audio-quality "$QUALITY" \
        --embed-metadata \
        --embed-thumbnail \
        --add-metadata \
        --restrict-filenames \
        --no-warnings \
        --progress \
        --newline \
        -o "$output_template" \
        "$url"
    
    local exit_code=$?
    echo
    
    if [ $exit_code -eq 0 ]; then
        print_success "Download completed successfully!"
        
        # Trigger Navidrome library scan
        print_status "Triggering library scan..."
        if docker exec navidrome /app/navidrome --configfile /data/navidrome.toml scan >/dev/null 2>&1; then
            print_success "Library scan completed"
        else
            print_warning "Library scan failed (Navidrome may not be running)"
        fi
        
        return 0
    else
        print_error "Download failed with exit code: $exit_code"
        return 1
    fi
}

# Main function
main() {
    echo "=================================================="
    echo "         YouTube Music Downloader v2.0"
    echo "=================================================="
    echo
    
    if [ $# -eq 0 ]; then
        print_error "No URL provided"
        echo
        echo "Usage: $0 <YouTube_URL> [quality] [format]"
        echo
        echo "Examples:"
        echo "  $0 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
        echo "  $0 'https://www.youtube.com/playlist?list=PLxxxxxx' 320 mp3"
        echo
        echo "Quality options: best, 320, 256, 192, 128"
        echo "Format options: mp3, m4a, flac"
        echo
        exit 1
    fi
    
    local url="$1"
    
    # Validate URL
    if ! validate_url "$url"; then
        exit 1
    fi
    
    # Create download directory
    mkdir -p "$DOWNLOAD_DIR"
    
    # Check if it's a playlist
    if [[ $url == *"playlist"* ]]; then
        print_status "Detected YouTube playlist"
    else
        print_status "Detected single video"
    fi
    
    # Start download
    if download_content "$url"; then
        echo
        print_success "=== Download Session Completed ==="
        print_status "Files saved to: $DOWNLOAD_DIR"
        print_status "Access your music at: http://$(hostname -I | awk '{print $1}'):4533"
    else
        echo
        print_error "=== Download Session Failed ==="
        exit 1
    fi
}

# Check dependencies
if ! command -v yt-dlp &> /dev/null; then
    print_error "yt-dlp is not installed"
    print_status "Installing yt-dlp..."
    pip3 install --user yt-dlp
fi

# Run main function with all arguments
main "$@"