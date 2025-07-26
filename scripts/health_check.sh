#!/bin/bash

# System Health Monitor Script
# Monitors system resources and service health

# Load configuration
source "$(dirname "$0")/../config/config.env" 2>/dev/null || {
    echo "Warning: config.env not found, using defaults"
}

# Set up logging
LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/health.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check disk space
check_disk_space() {
    local usage=$(df /home/pi/music | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$usage" -gt 90 ]; then
        log "WARNING: Disk usage is ${usage}% - cleanup needed"
        return 1
    elif [ "$usage" -gt 80 ]; then
        log "INFO: Disk usage is ${usage}% - monitor closely"
        return 0
    else
        log "INFO: Disk usage is ${usage}% - healthy"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local mem_usage_int=$(echo "$mem_usage" | cut -d. -f1)
    
    if [ "$mem_usage_int" -gt 90 ]; then
        log "WARNING: Memory usage is ${mem_usage}% - may need restart"
        return 1
    elif [ "$mem_usage_int" -gt 80 ]; then
        log "INFO: Memory usage is ${mem_usage}% - monitor closely"
        return 0
    else
        log "INFO: Memory usage is ${mem_usage}% - healthy"
        return 0
    fi
}

# Function to check CPU temperature (Pi specific)
check_temperature() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        
        if [ "$temp_c" -gt 80 ]; then
            log "WARNING: CPU temperature is ${temp_c}°C - overheating risk"
            return 1
        elif [ "$temp_c" -gt 70 ]; then
            log "INFO: CPU temperature is ${temp_c}°C - warm but acceptable"
            return 0
        else
            log "INFO: CPU temperature is ${temp_c}°C - healthy"
            return 0
        fi
    else
        log "INFO: Temperature monitoring not available"
        return 0
    fi
}

# Function to check docker containers
check_docker_services() {
    if command -v docker > /dev/null; then
        local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2)
        
        if [ -z "$containers" ]; then
            log "WARNING: No Docker containers running"
            return 1
        fi
        
        while IFS=$'\t' read -r name status; do
            if echo "$status" | grep -q "Up"; then
                log "INFO: Container $name is running ($status)"
            else
                log "WARNING: Container $name is not running ($status)"
                return 1
            fi
        done <<< "$containers"
        
        return 0
    else
        log "WARNING: Docker not available"
        return 1
    fi
}

# Function to check service connectivity
check_service_connectivity() {
    # Check Navidrome
    if curl -s "http://localhost:4533/ping" > /dev/null; then
        log "INFO: Navidrome service is responding"
    else
        log "WARNING: Navidrome service is not responding"
        return 1
    fi
    
    # Check download interface
    if curl -s "http://localhost:8080/health" > /dev/null; then
        log "INFO: Download interface is responding"
    else
        log "WARNING: Download interface is not responding"
        return 1
    fi
    
    return 0
}

# Function to check download queue
check_download_queue() {
    local queue_file="$(dirname "$0")/../queue/download_queue.txt"
    
    if [ -f "$queue_file" ]; then
        local queue_size=$(wc -l < "$queue_file" 2>/dev/null || echo "0")
        
        if [ "$queue_size" -gt 10 ]; then
            log "WARNING: Download queue has $queue_size items - may be stuck"
            return 1
        elif [ "$queue_size" -gt 0 ]; then
            log "INFO: Download queue has $queue_size items pending"
            return 0
        else
            log "INFO: Download queue is empty"
            return 0
        fi
    else
        log "INFO: No download queue file found"
        return 0
    fi
}

# Function to generate health report
generate_health_report() {
    local report_file="$LOG_DIR/health_report.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Collect system stats
    local disk_usage=$(df /home/pi/music | tail -1 | awk '{print $5}' | sed 's/%//')
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    local uptime_info=$(uptime -p)
    
    # Get temperature if available
    local temperature="null"
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temperature=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    fi
    
    # Count music files
    local music_count=$(find /home/pi/music -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.ogg" -o -name "*.flac" \) 2>/dev/null | wc -l)
    
    # Get Docker status
    local docker_status="unknown"
    if command -v docker > /dev/null; then
        if docker ps > /dev/null 2>&1; then
            docker_status="running"
        else
            docker_status="error"
        fi
    else
        docker_status="not_installed"
    fi
    
    # Create JSON report
    cat > "$report_file" <<EOF
{
    "timestamp": "$timestamp",
    "system": {
        "disk_usage_percent": $disk_usage,
        "memory_usage_percent": $mem_usage,
        "cpu_temperature_celsius": $temperature,
        "load_average": "$load_avg",
        "uptime": "$uptime_info"
    },
    "services": {
        "docker_status": "$docker_status"
    },
    "music_library": {
        "total_files": $music_count
    }
}
EOF
    
    log "Health report generated: $report_file"
}

# Main health check function
main() {
    log "=== Health Check Started ==="
    
    local overall_status=0
    
    # Run all checks
    check_disk_space || overall_status=1
    check_memory || overall_status=1
    check_temperature || overall_status=1
    check_docker_services || overall_status=1
    check_service_connectivity || overall_status=1
    check_download_queue || overall_status=1
    
    # Generate report
    generate_health_report
    
    if [ $overall_status -eq 0 ]; then
        log "=== Health Check Completed - All systems healthy ==="
    else
        log "=== Health Check Completed - Issues detected ==="
    fi
    
    return $overall_status
}

# Run health check
main "$@"
