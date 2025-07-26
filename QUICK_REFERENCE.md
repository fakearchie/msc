# Quick Reference - Raspberry Pi Music Server

## 🚀 Quick Start Commands

```bash
# Start the server
./scripts/music-server.sh start

# Stop the server  
./scripts/music-server.sh stop

# Check status
./scripts/music-server.sh status

# Download music
./scripts/music-server.sh download "https://youtube.com/watch?v=VIDEO_ID"
```

## 🌐 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Music Player** | `http://pi-ip:4533` | Main Navidrome interface |
| **Downloads** | `http://pi-ip:8080` | Web form for YouTube downloads |
| **Combined** | `http://pi-ip` | Both services via Nginx proxy |

## 📱 Mobile Apps Setup

### Android
- **DSub** (Recommended) - Free, excellent interface
- **Substreamer** - Premium, advanced features
- **Ultrasonic** - Open source alternative

### iOS  
- **Play:Sub** - Premium, beautiful design
- **Substreamer** - Cross-platform premium
- **iSub** - Free alternative

### Configuration
- **Server**: `http://your-pi-ip:4533`
- **Username**: Your Navidrome username
- **Password**: Your Navidrome password
- **Format**: Subsonic/Navidrome

## 🔧 Essential Commands

### Service Management
```bash
# View logs
docker-compose logs -f navidrome

# Restart specific service
docker-compose restart navidrome

# Update all services
./scripts/music-server.sh update
```

### Downloads
```bash
# Manual download
./scripts/download_music.sh "YOUTUBE_URL"

# Monitor download progress
tail -f logs/downloader.log

# Check download queue
cat queue/download_queue.txt
```

### Library Management
```bash
# Full maintenance (recommended weekly)
./scripts/library_manager.sh full

# Quick scan (after adding music)
./scripts/library_manager.sh scan

# Find and remove duplicates
./scripts/library_manager.sh clean
```

### Health & Monitoring
```bash
# System health check
./scripts/health_check.sh

# View system resources
htop

# Check disk space
df -h /home/pi/music
```

## 📁 Important File Locations

| Path | Purpose |
|------|---------|
| `/home/pi/music/` | Music storage |
| `/home/pi/spotify-clone/config/config.env` | Main configuration |
| `/home/pi/spotify-clone/logs/` | All log files |
| `/home/pi/spotify-clone/queue/` | Download queue |

## ⚡ Quick Troubleshooting

### Services Won't Start
```bash
# Check Docker status
sudo systemctl status docker

# View detailed logs
docker-compose logs

# Restart Docker
sudo systemctl restart docker
```

### Downloads Failing
```bash
# Update yt-dlp
sudo yt-dlp -U

# Test manual download
yt-dlp --extract-audio "YOUTUBE_URL"

# Check logs
tail logs/downloader.log
```

### Can't Access Web Interface
```bash
# Check container status
docker-compose ps

# Restart web service
docker-compose restart youtube_downloader

# Check firewall
sudo ufw status
```

### Music Not Showing
```bash
# Trigger manual scan
./scripts/library_manager.sh scan

# Check file permissions
ls -la /home/pi/music/

# Fix permissions
sudo chown -R pi:pi /home/pi/music
```

## 🔑 Default Credentials

- **Username**: admin
- **Password**: Check `config/config.env`
- **Change immediately** after first login!

## 📊 Performance Tips

### For Better Performance
- Use USB 3.0 SSD for music storage
- Set `MAX_CONCURRENT_DOWNLOADS=1` for slower internet
- Enable GPU memory split: `sudo raspi-config` → Advanced → Memory Split → 128

### Storage Management
```bash
# Check large files
du -sh /home/pi/music/* | sort -hr

# Clean old logs
find logs/ -name "*.log" -mtime +7 -delete

# Docker cleanup
docker system prune -f
```

## 🆘 Emergency Recovery

### Complete Reset
```bash
# Stop everything
./scripts/music-server.sh stop

# Remove all containers
docker-compose down -v

# Restart fresh
./scripts/music-server.sh start
```

### Backup Essential Data
```bash
# Backup configuration and logs
tar -czf backup-$(date +%Y%m%d).tar.gz config/ logs/

# Backup music library list
find /home/pi/music -name "*.mp3" > music-list-$(date +%Y%m%d).txt
```

## 🌟 Pro Tips

1. **Set up monitoring playlists** in `config.env` for automatic downloads
2. **Use the web interface** for one-off downloads
3. **Enable downloads in mobile apps** for offline listening
4. **Run weekly maintenance** with `library_manager.sh full`
5. **Monitor disk space** regularly - music files add up quickly!
6. **Set up VPN access** for secure remote listening
7. **Use quality `best`** for high-quality downloads
8. **Organize by `artist/album`** for better mobile app experience

## 📞 Getting Help

1. **Check logs first**: `./scripts/music-server.sh logs`
2. **Run health check**: `./scripts/health_check.sh` 
3. **Verify config**: `cat config/config.env`
4. **Test components individually**: Use manual download scripts
5. **Check system resources**: `htop` and `df -h`

---

**Remember**: Keep your Pi cool, your storage organized, and your passwords secure! 🎵
