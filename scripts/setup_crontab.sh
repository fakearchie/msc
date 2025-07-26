#!/bin/bash

# Crontab Setup Script for Music Server
# Sets up automated tasks for music downloading and library management

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up crontab for music server automation...${NC}"

# Create the crontab entries
CRON_ENTRIES="
# Music Server Automation
# Check for new downloads every hour
0 * * * * /home/pi/spotify-clone/scripts/download_monitor.sh >> /home/pi/spotify-clone/logs/cron.log 2>&1

# Library maintenance every day at 3 AM
0 3 * * * /home/pi/spotify-clone/scripts/library_manager.sh full >> /home/pi/spotify-clone/logs/cron.log 2>&1

# Quick library scan every 15 minutes
*/15 * * * * /home/pi/spotify-clone/scripts/library_manager.sh scan >> /home/pi/spotify-clone/logs/cron.log 2>&1

# Log rotation weekly (Sunday at 2 AM)
0 2 * * 0 find /home/pi/spotify-clone/logs -name '*.log' -mtime +7 -delete

# System cleanup monthly (first day of month at 4 AM)
0 4 1 * * docker system prune -f >> /home/pi/spotify-clone/logs/cron.log 2>&1
"

# Install the crontab
echo "$CRON_ENTRIES" | crontab -

echo -e "${GREEN}Crontab installed successfully!${NC}"
echo ""
echo -e "${YELLOW}Scheduled tasks:${NC}"
echo "• Download monitoring: Every hour"
echo "• Library maintenance: Daily at 3 AM"
echo "• Quick library scan: Every 15 minutes"
echo "• Log cleanup: Weekly on Sunday at 2 AM"
echo "• System cleanup: Monthly on 1st at 4 AM"
echo ""
echo "To view current crontab: crontab -l"
echo "To edit crontab: crontab -e"
