#!/bin/bash

# Music Library Management Script
# Handles scanning, organizing, and maintaining the music library

# Load configuration
source "$(dirname "$0")/../config/config.env" 2>/dev/null || {
    echo "Warning: config.env not found, using defaults"
    MUSIC_PATH="/home/pi/music"
}

# Set up logging
LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/library.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to scan for duplicate files
find_duplicates() {
    log "Scanning for duplicate files..."
    
    find "$MUSIC_PATH" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" -o -name "*.flac" \) -exec md5sum {} \; | \
    sort | uniq -d -w 32 | while read -r hash file; do
        log "Duplicate found: $file (hash: $hash)"
        echo "$file" >> "$LOG_DIR/duplicates.txt"
    done
    
    if [ -f "$LOG_DIR/duplicates.txt" ]; then
        local count=$(wc -l < "$LOG_DIR/duplicates.txt")
        log "Found $count duplicate files. Check $LOG_DIR/duplicates.txt for details."
    else
        log "No duplicate files found."
    fi
}

# Function to fix file permissions
fix_permissions() {
    log "Fixing file permissions..."
    
    # Set directory permissions
    find "$MUSIC_PATH" -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find "$MUSIC_PATH" -type f -exec chmod 644 {} \;
    
    # Ensure ownership is correct
    sudo chown -R pi:pi "$MUSIC_PATH" 2>/dev/null || {
        log "Warning: Could not change ownership (not running as root)"
    }
    
    log "Permissions fixed."
}

# Function to clean empty directories
clean_empty_dirs() {
    log "Cleaning empty directories..."
    
    local count=0
    while IFS= read -r -d '' dir; do
        rmdir "$dir" 2>/dev/null && {
            log "Removed empty directory: $dir"
            ((count++))
        }
    done < <(find "$MUSIC_PATH" -type d -empty -print0)
    
    log "Removed $count empty directories."
}

# Function to generate library statistics
generate_stats() {
    log "Generating library statistics..."
    
    local stats_file="$LOG_DIR/library_stats.txt"
    
    {
        echo "Music Library Statistics - $(date)"
        echo "========================================"
        echo
        
        echo "File Counts:"
        find "$MUSIC_PATH" -name "*.mp3" | wc -l | xargs echo "MP3 files:"
        find "$MUSIC_PATH" -name "*.m4a" | wc -l | xargs echo "M4A files:"
        find "$MUSIC_PATH" -name "*.ogg" | wc -l | xargs echo "OGG files:"
        find "$MUSIC_PATH" -name "*.flac" | wc -l | xargs echo "FLAC files:"
        find "$MUSIC_PATH" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" -o -name "*.flac" \) | wc -l | xargs echo "Total audio files:"
        echo
        
        echo "Directory Structure:"
        find "$MUSIC_PATH" -type d | wc -l | xargs echo "Total directories:"
        find "$MUSIC_PATH" -maxdepth 1 -type d | tail -n +2 | wc -l | xargs echo "Artists/Top-level directories:"
        echo
        
        echo "Storage Usage:"
        du -sh "$MUSIC_PATH" | cut -f1 | xargs echo "Total size:"
        df -h "$MUSIC_PATH" | tail -1 | awk '{print "Available space: " $4 " (" $5 " used)"}'
        echo
        
        echo "Recent Activity:"
        find "$MUSIC_PATH" -type f -mtime -1 | wc -l | xargs echo "Files added in last 24 hours:"
        find "$MUSIC_PATH" -type f -mtime -7 | wc -l | xargs echo "Files added in last week:"
        echo
        
    } > "$stats_file"
    
    log "Statistics saved to: $stats_file"
    cat "$stats_file"
}

# Function to trigger Navidrome rescan
trigger_rescan() {
    log "Triggering Navidrome rescan..."
    
    if command -v docker > /dev/null; then
        if docker ps | grep -q navidrome; then
            docker exec navidrome /app/navidrome --configfile /data/navidrome.toml --scan 2>/dev/null || {
                log "Warning: Failed to trigger Navidrome rescan via docker exec"
                # Try alternative method via API
                local navidrome_url="http://localhost:4533"
                curl -s "$navidrome_url/api/scan" -X POST 2>/dev/null || {
                    log "Warning: Failed to trigger rescan via API as well"
                }
            }
            log "Navidrome rescan triggered"
        else
            log "Navidrome container not running"
        fi
    else
        log "Docker not available, cannot trigger Navidrome rescan"
    fi
}

# Function to backup library metadata
backup_metadata() {
    local backup_dir="$(dirname "$0")/../backups"
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/library_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log "Creating metadata backup..."
    
    # Create a list of all music files with their metadata
    find "$MUSIC_PATH" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" -o -name "*.flac" \) \
        -exec stat -c "%n|%Y|%s" {} \; > "$backup_dir/file_list.txt"
    
    # Backup configuration and logs
    tar -czf "$backup_file" -C "$(dirname "$0")/.." \
        config/ logs/ "$backup_dir/file_list.txt" 2>/dev/null || {
        log "Warning: Backup creation had some issues"
    }
    
    # Clean old backups (keep last 7 days)
    find "$backup_dir" -name "library_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    
    log "Backup created: $backup_file"
}

# Function to validate music files
validate_files() {
    log "Validating music files..."
    
    local corrupt_files=0
    local invalid_files="$LOG_DIR/invalid_files.txt"
    rm -f "$invalid_files"
    
    find "$MUSIC_PATH" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" -o -name "*.flac" \) | while read -r file; do
        # Check if file is readable and has content
        if [ ! -r "$file" ] || [ ! -s "$file" ]; then
            echo "$file" >> "$invalid_files"
            log "Invalid file: $file"
            ((corrupt_files++))
        fi
        
        # Check file format (basic validation)
        case "${file##*.}" in
            mp3)
                if ! file "$file" | grep -q "MPEG"; then
                    echo "$file" >> "$invalid_files"
                    log "Invalid MP3 file: $file"
                    ((corrupt_files++))
                fi
                ;;
            m4a)
                if ! file "$file" | grep -q "ISO Media"; then
                    echo "$file" >> "$invalid_files"
                    log "Invalid M4A file: $file"
                    ((corrupt_files++))
                fi
                ;;
        esac
    done
    
    if [ -f "$invalid_files" ]; then
        local count=$(wc -l < "$invalid_files")
        log "Found $count invalid/corrupt files. Check $invalid_files for details."
    else
        log "All music files appear to be valid."
    fi
}

# Main function
main() {
    local action="${1:-scan}"
    
    log "=== Library Management - Action: $action ==="
    
    case "$action" in
        "scan")
            generate_stats
            trigger_rescan
            ;;
        "clean")
            fix_permissions
            clean_empty_dirs
            find_duplicates
            ;;
        "validate")
            validate_files
            ;;
        "backup")
            backup_metadata
            ;;
        "full")
            validate_files
            fix_permissions
            clean_empty_dirs
            find_duplicates
            generate_stats
            backup_metadata
            trigger_rescan
            ;;
        *)
            echo "Usage: $0 [scan|clean|validate|backup|full]"
            echo "  scan     - Generate stats and trigger rescan (default)"
            echo "  clean    - Fix permissions, remove empty dirs, find duplicates"
            echo "  validate - Check for corrupt/invalid files"
            echo "  backup   - Create metadata backup"
            echo "  full     - Run all maintenance tasks"
            exit 1
            ;;
    esac
    
    log "=== Library Management Completed ==="
}

# Run main function
main "$@"
