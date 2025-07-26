# Complete Setup Guide for Raspberry Pi Music Server

## Prerequisites

- Raspberry Pi 5 with 8GB RAM
- Debian 12 (aarch64) installed
- At least 32GB storage (preferably 128GB+ for music)
- Internet connection
- SSH access (optional but recommended)

## Step-by-Step Installation

### 1. Initial System Setup

```bash
# Update the system
sudo apt update && sudo apt upgrade -y

# Create project directory
mkdir -p /home/pi/spotify-clone
cd /home/pi/spotify-clone

# Clone or download this project
# (If you have this as a git repository)
# git clone <repository-url> .
```

### 2. Run the Installation Script

```bash
# Make the install script executable
chmod +x scripts/install.sh

# Run the installation
sudo scripts/install.sh
```

**Important:** Reboot after installation:
```bash
sudo reboot
```

### 3. Configuration

Edit the configuration file:
```bash
nano config/config.env
```

**Key settings to change:**
- `ADMIN_PASSWORD`: Change from default
- `MONITOR_PLAYLISTS`: Add your YouTube playlist URLs
- `AUDIO_QUALITY`: Set preferred quality (best/320/192)
- `FOLDER_STRUCTURE`: Choose organization method

### 4. Start the Services

```bash
cd /home/pi/spotify-clone

# Start all services
docker-compose up -d

# Check if services are running
docker-compose ps
```

### 5. Setup Automation

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Setup crontab for automation
scripts/setup_crontab.sh

# Enable systemd services
sudo systemctl enable music-downloader.timer
sudo systemctl start music-downloader.timer
```

### 6. Initial Testing

```bash
# Test manual download
scripts/download_music.sh "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Check library status
scripts/library_manager.sh scan

# Run health check
scripts/health_check.sh
```

## Accessing Your Music Server

### Web Interfaces

1. **Navidrome (Music Player)**: `http://your-pi-ip:4533`
   - Default login: admin / (password from config.env)
   
2. **Download Interface**: `http://your-pi-ip:8080`
   - Paste YouTube URLs to download

3. **Combined Interface (via Nginx)**: `http://your-pi-ip`
   - Main player at root
   - Downloads at `/download/`

### Mobile Apps

Install these apps and configure with your server details:

**Android:**
- **DSub** (Free, excellent interface)
- **Substreamer** (Premium, great features)
- **Ultrasonic** (Open source)

**iOS:**
- **Play:Sub** (Premium, beautiful interface)
- **Substreamer** (Premium, cross-platform)
- **iSub** (Free alternative)

**Web-based:**
- **Aurial** (Works in any browser)
- **Subfire** (Chrome/desktop app)

### Server Configuration for Apps

**Server URL**: `http://your-pi-ip:4533`
**Username**: Your Navidrome username
**Password**: Your Navidrome password
**Server Type**: Subsonic/Navidrome

## File Structure Explanation

```
/home/pi/
├── music/                    # Music storage directory
│   ├── downloads/           # Temporary download location
│   └── library/            # Organized music library
├── spotify-clone/          # Project directory
│   ├── config/
│   │   ├── config.env      # Main configuration
│   │   └── nginx.conf      # Nginx proxy config
│   ├── scripts/
│   │   ├── install.sh      # Initial installation
│   │   ├── download_music.sh    # Manual download script
│   │   ├── download_monitor.sh  # Automatic monitoring
│   │   ├── library_manager.sh   # Library maintenance
│   │   ├── health_check.sh      # System monitoring
│   │   └── setup_crontab.sh     # Automation setup
│   ├── web/
│   │   ├── app.py          # Download web interface
│   │   └── templates/      # Web interface templates
│   ├── logs/               # All log files
│   ├── cache/              # Playlist cache files
│   ├── queue/              # Download queue
│   └── docker-compose.yml  # Service definitions
```

## Usage Examples

### Manual Downloads

```bash
# Download a single song
scripts/download_music.sh "https://www.youtube.com/watch?v=VIDEO_ID"

# Download a playlist
scripts/download_music.sh "https://www.youtube.com/playlist?list=PLAYLIST_ID"

# Download to specific directory
scripts/download_music.sh "https://youtube.com/watch?v=ID" "/custom/path"
```

### Library Management

```bash
# Full library maintenance
scripts/library_manager.sh full

# Quick scan only
scripts/library_manager.sh scan

# Clean up duplicates and fix permissions
scripts/library_manager.sh clean

# Validate all music files
scripts/library_manager.sh validate

# Create backup
scripts/library_manager.sh backup
```

### Monitoring and Logs

```bash
# View real-time logs
docker-compose logs -f navidrome
docker-compose logs -f youtube_downloader

# Check system health
scripts/health_check.sh

# View download logs
tail -f logs/downloader.log

# View monitoring logs
tail -f logs/monitor.log
```

## Troubleshooting

### Common Issues

**1. Services not starting:**
```bash
# Check Docker status
sudo systemctl status docker

# View service logs
docker-compose logs

# Restart all services
docker-compose restart
```

**2. Download failures:**
```bash
# Check yt-dlp version
yt-dlp --version

# Update yt-dlp
sudo yt-dlp -U

# Test download manually
yt-dlp --extract-audio --audio-format mp3 "YOUTUBE_URL"
```

**3. Permission issues:**
```bash
# Fix music directory permissions
sudo chown -R pi:pi /home/pi/music
sudo chmod -R 755 /home/pi/music

# Fix script permissions
chmod +x scripts/*.sh
```

**4. Storage full:**
```bash
# Check disk usage
df -h /home/pi/music

# Find large files
du -sh /home/pi/music/* | sort -hr

# Clean up logs
find logs/ -name "*.log" -mtime +7 -delete
```

### Performance Optimization

**For better performance on Pi 5:**

1. **Increase swap space:**
```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

2. **Use faster storage:**
- Use USB 3.0 SSD for music storage
- Keep system on fast SD card

3. **Optimize Docker:**
```bash
# Add to /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## Security Considerations

### Network Access

**Local Network Only (Recommended):**
- Access only via local IP addresses
- Use VPN for remote access

**External Access (Advanced):**
- Set up reverse proxy with SSL
- Use domain name with Let's Encrypt
- Configure firewall rules
- Enable fail2ban

### Authentication

1. **Change default passwords** in `config/config.env`
2. **Disable user registration** after creating accounts
3. **Use strong passwords** for all accounts
4. **Regular security updates:**
```bash
sudo apt update && sudo apt upgrade -y
docker-compose pull && docker-compose up -d
```

## Backup and Recovery

### Automated Backups

The system automatically backs up:
- Configuration files
- User databases
- Playlist information
- Library metadata

### Manual Backup

```bash
# Backup everything important
tar -czf music-server-backup-$(date +%Y%m%d).tar.gz \
  config/ \
  logs/ \
  /home/pi/music \
  docker-compose.yml
```

### Recovery

```bash
# Restore from backup
tar -xzf music-server-backup-YYYYMMDD.tar.gz

# Restart services
docker-compose down && docker-compose up -d

# Trigger full rescan
scripts/library_manager.sh scan
```

## Advanced Configuration

### Custom Audio Formats

Edit `scripts/download_music.sh` to change audio settings:
```bash
# For FLAC (lossless)
AUDIO_FORMAT=flac
AUDIO_QUALITY=best

# For specific bitrate MP3
AUDIO_FORMAT=mp3
AUDIO_QUALITY=192
```

### Multiple Music Directories

Add additional volumes to `docker-compose.yml`:
```yaml
volumes:
  - /home/pi/music:/music:ro
  - /media/usb/music:/music2:ro
```

### Custom Metadata

Modify the download script to add custom metadata:
```bash
--embed-metadata \
--add-metadata \
--metadata-from-title "%(artist)s - %(title)s"
```

## Getting Help

1. Check the logs: `tail -f logs/*.log`
2. Run health check: `scripts/health_check.sh`
3. Verify configuration: `cat config/config.env`
4. Test individual components manually
5. Check Docker status: `docker-compose ps`

For issues with specific components:
- **yt-dlp issues**: Check GitHub issues at yt-dlp/yt-dlp
- **Navidrome issues**: Check Navidrome documentation
- **Docker issues**: Check Docker logs and system resources
