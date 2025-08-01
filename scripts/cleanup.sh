#!/bin/bash

# Clean up temporary files and unused features
# Remove redundant scripts and optimize the system

echo "🧹 Cleaning up unnecessary files and features..."

# Remove duplicate scripts
if [ -f "upgrade-to-v2.sh" ] && [ -f "scripts/upgrade-to-v2.sh" ]; then
    rm -f "upgrade-to-v2.sh"
    echo "✅ Removed duplicate upgrade-to-v2.sh"
fi

if [ -f "install.sh" ] && [ -f "scripts/install.sh" ]; then
    rm -f "install.sh" 
    echo "✅ Removed duplicate install.sh"
fi

# Clean up temporary files
find . -name "*.tmp" -type f -delete 2>/dev/null && echo "✅ Removed .tmp files"
find . -name "*.cache" -type f -delete 2>/dev/null && echo "✅ Removed .cache files"
find . -name "*.log.*" -type f -mtime +7 -delete 2>/dev/null && echo "✅ Removed old log files"
find . -name ".DS_Store" -type f -delete 2>/dev/null && echo "✅ Removed .DS_Store files"
find . -name "Thumbs.db" -type f -delete 2>/dev/null && echo "✅ Removed Thumbs.db files"

# Clean up Docker if available
if command -v docker > /dev/null; then
    docker system prune -f > /dev/null 2>&1 && echo "✅ Cleaned Docker system"
    docker volume prune -f > /dev/null 2>&1 && echo "✅ Cleaned Docker volumes"
fi

# Remove unused documentation that duplicates information
if [ -f "ENHANCEMENT_SUMMARY.md" ]; then
    rm -f "ENHANCEMENT_SUMMARY.md"
    echo "✅ Removed redundant ENHANCEMENT_SUMMARY.md"
fi

# Clean up music directory from incomplete downloads
if [ -d "/home/pi/music" ]; then
    find "/home/pi/music" -name "*.part" -type f -delete 2>/dev/null && echo "✅ Removed incomplete downloads"
    find "/home/pi/music" -name "*.ytdl" -type f -delete 2>/dev/null && echo "✅ Removed download temp files"
    find "/home/pi/music" -empty -type d -delete 2>/dev/null && echo "✅ Removed empty directories"
fi

# Optimize script permissions
find scripts/ -name "*.sh" -exec chmod +x {} \; 2>/dev/null && echo "✅ Fixed script permissions"

# Clean up logs older than 30 days
find logs/ -name "*.log" -type f -mtime +30 -delete 2>/dev/null && echo "✅ Removed old logs (30+ days)"

echo ""
echo "🎉 Cleanup completed! Your music server is now optimized."
echo ""
echo "📊 Current disk usage:"
df -h . | tail -1

echo ""
echo "📁 Active services:"
if command -v docker > /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi
