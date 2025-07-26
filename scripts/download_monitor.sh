#!/bin/bash

# Download Monitor Script
# Monitors specified playlists and downloads new content automatically

# Load configuration
source "$(dirname "$0")/../config/config.env" 2>/dev/null || {
    echo "Warning: config.env not found, using defaults"
    MONITOR_PLAYLISTS=""
    PLAYLIST_CHECK_INTERVAL=60
    MUSIC_PATH="/home/pi/music"
}

# Set up logging
LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/monitor.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if a playlist has new content
check_playlist_updates() {
    local playlist_url="$1"
    local cache_dir="$(dirname "$0")/../cache"
    mkdir -p "$cache_dir"
    
    local playlist_id=$(echo "$playlist_url" | sed -n 's/.*list=\([^&]*\).*/\1/p')
    local cache_file="$cache_dir/playlist_${playlist_id}.cache"
    
    log "Checking playlist for updates: $playlist_url"
    
    # Get current playlist info
    local current_info=$(yt-dlp --flat-playlist --dump-json "$playlist_url" 2>/dev/null | jq -r '.id' | sort)
    
    if [ -z "$current_info" ]; then
        log "Failed to fetch playlist info for: $playlist_url"
        return 1
    fi
    
    # Compare with cached info
    if [ -f "$cache_file" ]; then
        local cached_info=$(cat "$cache_file")
        
        # Check for differences
        local new_videos=$(comm -13 <(echo "$cached_info") <(echo "$current_info"))
        
        if [ -n "$new_videos" ]; then
            log "New videos found in playlist: $playlist_url"
            echo "$new_videos" | while read -r video_id; do
                if [ -n "$video_id" ]; then
                    log "New video: $video_id"
                fi
            done
            
            # Update cache
            echo "$current_info" > "$cache_file"
            return 0  # New content found
        else
            log "No new content in playlist: $playlist_url"
            return 1  # No new content
        fi
    else
        # First time checking this playlist
        log "First time checking playlist, creating cache: $playlist_url"
        echo "$current_info" > "$cache_file"
        return 0  # Treat as new content
    fi
}

# Function to download new content from a playlist
download_new_content() {
    local playlist_url="$1"
    
    log "Downloading new content from: $playlist_url"
    
    # Use the download script to get the latest content
    "$(dirname "$0")/download_music.sh" "$playlist_url" "$MUSIC_PATH"
}

# Function to process queue file
process_download_queue() {
    local queue_file="$(dirname "$0")/../queue/download_queue.txt"
    
    if [ -f "$queue_file" ] && [ -s "$queue_file" ]; then
        log "Processing download queue..."
        
        while IFS= read -r url; do
            if [ -n "$url" ] && [[ "$url" != \#* ]]; then
                log "Processing queued URL: $url"
                "$(dirname "$0")/download_music.sh" "$url" "$MUSIC_PATH"
                
                # Remove processed URL from queue
                grep -v "^$url$" "$queue_file" > "${queue_file}.tmp" && mv "${queue_file}.tmp" "$queue_file"
            fi
        done < "$queue_file"
    fi
}

# Function to clean up old log files
cleanup_logs() {
    local max_age_days=7
    
    find "$LOG_DIR" -name "*.log" -type f -mtime +$max_age_days -delete 2>/dev/null || true
    log "Cleaned up log files older than $max_age_days days"
}

# Main monitoring loop
main() {
    log "=== Download Monitor Started ==="
    log "Monitor Playlists: $MONITOR_PLAYLISTS"
    log "Check Interval: $PLAYLIST_CHECK_INTERVAL minutes"
    
    # Create necessary directories
    mkdir -p "$(dirname "$0")/../cache"
    mkdir -p "$(dirname "$0")/../queue"
    
    while true; do
        log "Starting monitoring cycle..."
        
        # Process any queued downloads first
        process_download_queue
        
        # Check monitored playlists
        if [ -n "$MONITOR_PLAYLISTS" ]; then
            IFS=',' read -ra PLAYLISTS <<< "$MONITOR_PLAYLISTS"
            for playlist in "${PLAYLISTS[@]}"; do
                playlist=$(echo "$playlist" | xargs)  # Trim whitespace
                if [ -n "$playlist" ]; then
                    if check_playlist_updates "$playlist"; then
                        download_new_content "$playlist"
                    fi
                fi
            done
        fi
        
        # Clean up old logs weekly
        if [ $(($(date +%s) % 604800)) -lt 300 ]; then  # Once a week
            cleanup_logs
        fi
        
        log "Monitoring cycle completed. Sleeping for $PLAYLIST_CHECK_INTERVAL minutes..."
        sleep $((PLAYLIST_CHECK_INTERVAL * 60))
    done
}

# Handle script termination gracefully
trap 'log "Download monitor stopped"; exit 0' SIGTERM SIGINT

# If script is called with arguments, process them as one-time downloads
if [ $# -gt 0 ]; then
    for url in "$@"; do
        "$(dirname "$0")/download_music.sh" "$url" "$MUSIC_PATH"
    done
    exit 0
fi

# Run main monitoring loop
main
