#!/bin/bash

# YouTube Music Downloader Script
# Downloads music from YouTube with proper metadata and organization

# Load configuration
source "$(dirname "$0")/../config/config.env" 2>/dev/null || {
    echo "Warning: config.env not found, using defaults"
    AUDIO_QUALITY=${AUDIO_QUALITY:-"best"}
    AUDIO_FORMAT=${AUDIO_FORMAT:-"mp3"}
    MUSIC_PATH=${MUSIC_PATH:-"/home/pi/music"}
    FOLDER_STRUCTURE=${FOLDER_STRUCTURE:-"artist/album"}
    EMBED_METADATA=${EMBED_METADATA:-"true"}
    DOWNLOAD_THUMBNAILS=${DOWNLOAD_THUMBNAILS:-"true"}
}

# Set up logging
LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/downloader.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to download a single URL
download_url() {
    local url="$1"
    local output_dir="$2"
    
    log "Starting download: $url"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Build yt-dlp command based on configuration
    local cmd="yt-dlp"
    
    # Audio format and quality
    cmd="$cmd --extract-audio --audio-format $AUDIO_FORMAT --audio-quality $AUDIO_QUALITY"
    
    # Enhanced metadata extraction
    cmd="$cmd --embed-metadata --embed-subs --embed-thumbnail --add-metadata"
    cmd="$cmd --parse-metadata 'title:%(title)s' --parse-metadata 'uploader:%(artist)s'"
    cmd="$cmd --write-info-json --write-description --write-annotations"
    
    # Better filename formatting
    cmd="$cmd --restrict-filenames --no-overwrites"
    
    # Output template based on folder structure
    case "$FOLDER_STRUCTURE" in
        "artist/album")
            cmd="$cmd -o '$output_dir/%(uploader)s/%(playlist_title)s/%(title)s.%(ext)s'"
            ;;
        "artist")
            cmd="$cmd -o '$output_dir/%(uploader)s/%(title)s.%(ext)s'"
            ;;
        "flat")
            cmd="$cmd -o '$output_dir/%(title)s.%(ext)s'"
            ;;
        *)
            cmd="$cmd -o '$output_dir/%(uploader)s/%(playlist_title)s/%(title)s.%(ext)s'"
            ;;
    esac
    
    # Add metadata embedding
    if [ "$EMBED_METADATA" = "true" ]; then
        cmd="$cmd --embed-metadata --embed-subs"
    fi
    
    # Add thumbnail download
    if [ "$DOWNLOAD_THUMBNAILS" = "true" ]; then
        cmd="$cmd --embed-thumbnail --convert-thumbnails jpg"
    fi
    
    # Additional options for better compatibility
    cmd="$cmd --ignore-errors --no-playlist"
    cmd="$cmd --restrict-filenames"
    cmd="$cmd --prefer-ffmpeg"
    
    # Add the URL
    cmd="$cmd '$url'"
    
    # Execute the command
    log "Executing: $cmd"
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "Successfully downloaded: $url"
        return 0
    else
        log "Failed to download: $url"
        return 1
    fi
}

# Function to download a playlist
download_playlist() {
    local url="$1"
    local output_dir="$2"
    
    log "Starting playlist download: $url"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Build yt-dlp command for playlist
    local cmd="yt-dlp"
    
    # Audio format and quality
    cmd="$cmd --extract-audio --audio-format $AUDIO_FORMAT --audio-quality $AUDIO_QUALITY"
    
    # Output template for playlist
    case "$FOLDER_STRUCTURE" in
        "artist/album")
            cmd="$cmd -o '$output_dir/%(uploader)s/%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s'"
            ;;
        "artist")
            cmd="$cmd -o '$output_dir/%(uploader)s/%(playlist_index)02d - %(title)s.%(ext)s'"
            ;;
        "flat")
            cmd="$cmd -o '$output_dir/%(playlist_index)02d - %(title)s.%(ext)s'"
            ;;
        *)
            cmd="$cmd -o '$output_dir/%(uploader)s/%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s'"
            ;;
    esac
    
    # Add metadata embedding
    if [ "$EMBED_METADATA" = "true" ]; then
        cmd="$cmd --embed-metadata --write-info-json"
    fi
    
    # Add thumbnail download
    if [ "$DOWNLOAD_THUMBNAILS" = "true" ]; then
        cmd="$cmd --write-thumbnail --convert-thumbnails jpg"
    fi
    
    # Additional options
    cmd="$cmd --ignore-errors --yes-playlist"
    cmd="$cmd --restrict-filenames"
    cmd="$cmd --prefer-ffmpeg"
    
    # Add the URL
    cmd="$cmd '$url'"
    
    # Execute the command
    log "Executing: $cmd"
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "Successfully downloaded playlist: $url"
        return 0
    else
        log "Failed to download playlist: $url"
        return 1
    fi
}

# Function to organize downloaded files
organize_files() {
    local source_dir="$1"
    
    log "Organizing files in: $source_dir"
    
    # Remove invalid characters from filenames
    find "$source_dir" -type f -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" | while read -r file; do
        # Get directory and filename
        dir=$(dirname "$file")
        filename=$(basename "$file")
        
        # Clean filename (remove special characters that might cause issues)
        clean_filename=$(echo "$filename" | sed 's/[<>:"|?*]/_/g' | sed 's/__*/_/g')
        
        # Rename if needed
        if [ "$filename" != "$clean_filename" ]; then
            mv "$file" "$dir/$clean_filename"
            log "Renamed: $filename -> $clean_filename"
        fi
    done
    
    # Set proper permissions
    find "$source_dir" -type f -exec chmod 644 {} \;
    find "$source_dir" -type d -exec chmod 755 {} \;
    
    # Enhance metadata if enabled
    if [ "$AUTO_TAG_MUSIC" = "true" ]; then
        log "Enhancing metadata with external APIs..."
        if command -v python3 > /dev/null; then
            python3 "$(dirname "$0")/enhance_metadata.py" "$source_dir" || log "Metadata enhancement failed"
        else
            log "Python3 not found, skipping metadata enhancement"
        fi
    fi
    
    log "File organization completed"
}

# Main function
main() {
    local url="$1"
    local output_dir="${2:-$MUSIC_PATH}"
    
    if [ -z "$url" ]; then
        echo "Usage: $0 <youtube_url> [output_directory]"
        echo "Examples:"
        echo "  $0 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
        echo "  $0 'https://www.youtube.com/playlist?list=PLxxx' /custom/path"
        exit 1
    fi
    
    log "=== Music Download Session Started ==="
    log "URL: $url"
    log "Output Directory: $output_dir"
    log "Audio Format: $AUDIO_FORMAT"
    log "Audio Quality: $AUDIO_QUALITY"
    
    # Check if URL is a playlist
    if echo "$url" | grep -q "playlist"; then
        download_playlist "$url" "$output_dir"
    else
        download_url "$url" "$output_dir"
    fi
    
    # Organize downloaded files
    organize_files "$output_dir"
    
    # Trigger Navidrome rescan
    if command -v docker > /dev/null && docker ps | grep -q navidrome; then
        log "Triggering Navidrome rescan..."
        docker exec navidrome /app/navidrome --configfile /var/lib/navidrome/navidrome.toml --scan
    fi
    
    log "=== Download Session Completed ==="
}

# Run main function with all arguments
main "$@"
