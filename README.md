# 🎵 YouTube Download Pro - Modern Music Server

> **Transform your Raspberry Pi into a professional music streaming server with beautiful YouTube integration**

![Version](https://img.shields.io/badge/version-2.0-blue)
![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi-red)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ What's New in v2.0

### � **Completely Redesigned Interface**
- **Modern Dark Theme** with gradient backgrounds and glass-morphism effects
- **Smooth Animations** and professional transitions
- **Mobile-Responsive** design that works perfectly on phones and tablets
- **Smart Notifications** with beautiful icons and color-coded messages

### � **Enhanced Installation Experience**
- **One-Click Installation** - No more manual setup every time!
- **Auto-Update System** - Updates automatically from GitHub
- **Multiple Installation Methods** - Choose what works best for you
- **Server IP Auto-Detection** - No manual configuration needed

### 🔧 **Powerful New Features**
- **Auto-Paste from Clipboard** - Detects and auto-fills YouTube URLs
- **Keyboard Shortcuts** - Enter to download, Escape to close
- **Dashboard Integration** - Quick access to your music dashboard
- **Bookmarklet Option** - Works without browser extensions
- **Enhanced Error Handling** - Better feedback and recovery

---

## 🎯 Quick Start (3 Steps)

### **Step 1: Deploy to Your Pi**
```bash
# One-command setup with auto-updates
curl -sSL https://raw.githubusercontent.com/fakearchie/msc/main/scripts/setup-pro.sh | bash
```

### **Step 2: Install Browser Extension**
Visit: `http://YOUR_PI_IP:8080/install-extension` and click "Install Extension"

### **Step 3: Start Downloading**
Go to your Navidrome → Click the floating YouTube button → Paste URLs → Enjoy! �

## 📱 Mobile Apps & Access

### Access Points
| Service | URL | Purpose |
|---------|-----|---------|
| **🎵 Music Player** | `http://pi-ip:4533` | Main Navidrome interface |
| **⬇️ Downloads** | `http://pi-ip:8080` | YouTube download web form |
| **🌐 Combined** | `http://pi-ip` | Both via Nginx proxy |

### Recommended Mobile Apps

**Android:**
- **DSub** ⭐ (Free, excellent interface)
- **Substreamer** (Premium, advanced features)
- **Ultrasonic** (Open source)

**iOS:**
- **Play:Sub** ⭐ (Premium, beautiful design)
- **Substreamer** (Cross-platform)
- **iSub** (Free alternative)

**Web:**
- **Aurial** (Works in any browser)
- **Subfire** (Desktop app)

## 🏗️ Architecture & File Structure

```
/home/pi/
├── music/                     # 🎵 Music storage (your library)
│   ├── downloads/            # Temporary download staging
│   └── library/              # Organized final library
└── spotify-clone/            # 🏠 Project directory
    ├── 🐳 docker-compose.yml     # Service orchestration
    ├── 📁 config/
    │   ├── config.env         # Main configuration
    │   └── nginx.conf         # Proxy configuration
    ├── 📁 scripts/             # 🔧 Management scripts
    │   ├── install.sh         # One-time setup
    │   ├── music-server.sh    # Main control script
    │   ├── download_music.sh  # Manual downloads
    │   ├── download_monitor.sh # Automatic monitoring
    │   ├── library_manager.sh # Library maintenance
    │   └── health_check.sh    # System monitoring
    ├── 📁 web/                 # 🌐 Download web interface
    │   ├── app.py             # Flask application
    │   ├── templates/         # Web UI templates
    │   └── Dockerfile         # Container definition
    ├── 📁 logs/                # 📊 All system logs
    ├── 📁 cache/               # Playlist cache
    └── 📁 queue/               # Download queue
```

## 🎯 Core Capabilities

### Automatic Music Management
- **Smart Downloads**: Monitor YouTube playlists for new content
- **Quality Control**: Choose audio quality (best, 320kbps, 192kbps)
- **Metadata Embedding**: Automatic artist, title, album, artwork
- **Organization**: Flexible folder structures (Artist/Album, Artist, Flat)
- **Duplicate Detection**: Find and manage duplicate files
- **Health Monitoring**: Validate file integrity and system health

### User Experience
- **Instant Downloads**: Paste YouTube URL → get music in minutes
- **Offline Listening**: Download to mobile devices (like Spotify Premium)
- **Multi-User**: Individual accounts with customizable permissions
- **Cross-Platform**: Access from any device, anywhere
- **Fast Search**: Instant search across your entire library
- **Playlists**: Create and manage custom playlists

### System Management
- **Automated Maintenance**: Scheduled scanning, cleanup, backups
- **Resource Monitoring**: CPU, memory, disk, temperature tracking
- **Log Management**: Automatic rotation and cleanup
- **Security**: Rate limiting, authentication, secure headers
- **Updates**: Easy updates for all components

## ⚙️ Configuration

The main configuration file is `config/config.env`. Key settings:

```bash
# Authentication (CHANGE THESE!)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=YourSecurePassword123!

# Download Quality
AUDIO_QUALITY=best          # best, 320, 192, 128
AUDIO_FORMAT=mp3           # mp3, m4a, flac

# Organization
FOLDER_STRUCTURE=artist/album  # artist/album, artist, flat
EMBED_METADATA=true
DOWNLOAD_THUMBNAILS=true

# Automation
PLAYLIST_CHECK_INTERVAL=60     # Check playlists every 60 minutes
MONITOR_PLAYLISTS="https://www.youtube.com/playlist?list=YOUR_PLAYLIST_ID"
```

## 🛠️ Management Commands

```bash
# Service Control
./scripts/music-server.sh start    # Start all services
./scripts/music-server.sh stop     # Stop all services
./scripts/music-server.sh status   # Check service status
./scripts/music-server.sh logs     # View logs

# Downloads
./scripts/music-server.sh download "https://youtube.com/watch?v=ID"
./scripts/download_music.sh "https://youtube.com/playlist?list=ID"

# Library Management
./scripts/library_manager.sh full   # Complete maintenance
./scripts/library_manager.sh scan   # Quick scan
./scripts/library_manager.sh clean  # Remove duplicates, fix permissions

# System Health
./scripts/health_check.sh           # System health check
./scripts/music-server.sh update    # Update all components
```

## 📊 System Requirements

### Minimum
- Raspberry Pi 5 (4GB RAM)
- 32GB storage
- Debian 12 (aarch64)

### Recommended
- **Raspberry Pi 5 (8GB RAM)** ⭐
- **128GB+ USB 3.0 SSD** for music storage
- **Fast SD card** (Class 10+) for system
- **Stable internet** for downloads
- **Active cooling** for sustained performance

### Performance Expectations
- **Concurrent Users**: 5-10 simultaneous streams
- **Library Size**: 10,000+ songs without issues
- **Download Speed**: Depends on internet (typically 1-3 songs/minute)
- **Startup Time**: ~30 seconds for all services
- **Resource Usage**: ~2GB RAM, minimal CPU when idle

## 🔧 Advanced Features

### Automation & Monitoring
- **Playlist Monitoring**: Automatically download new songs from watched playlists
- **Health Checks**: Monitor system resources, service status, file integrity
- **Automatic Cleanup**: Remove old logs, temporary files, manage disk space
- **Scheduled Maintenance**: Daily/weekly library scans and optimization

### Customization
- **Custom Audio Formats**: FLAC for audiophiles, MP3 for compatibility
- **Flexible Organization**: Choose how music is organized in folders
- **Quality Profiles**: Different quality settings for different sources
- **Custom Metadata**: Add custom tags and information

### Integration
- **API Access**: Full REST API for custom integrations
- **Webhook Support**: Trigger actions on download completion
- **External Storage**: Support for USB drives, network storage
- **Backup & Sync**: Automated backups, sync between devices

## 📚 Documentation

- **[📖 Complete Setup Guide](SETUP_GUIDE.md)** - Detailed installation and configuration
- **[⚡ Quick Reference](QUICK_REFERENCE.md)** - Commands and troubleshooting
- **[🔧 Advanced Configuration](docs/ADVANCED.md)** - Expert settings and customization

## 🆘 Support & Troubleshooting

### Quick Diagnostics
```bash
./scripts/health_check.sh        # Check system health
./scripts/music-server.sh status # Check service status
docker-compose logs              # View service logs
```

### Common Issues
- **Services won't start**: Check Docker status and logs
- **Downloads failing**: Update yt-dlp, check internet connection
- **Can't access web**: Check firewall, container status
- **Music not showing**: Trigger manual scan, check permissions

### Getting Help
1. Run health check and read logs
2. Check the troubleshooting guide
3. Verify configuration settings
4. Test individual components
5. Check system resources

## 🌟 Why Choose This Solution?

### vs. Spotify Premium
✅ **One-time setup** vs. monthly subscription  
✅ **Own your music** vs. lose access if subscription ends  
✅ **No ads, ever** vs. occasional ads even with Premium  
✅ **Unlimited storage** vs. download limits  
✅ **Any audio source** vs. only Spotify catalog  

### vs. Other Self-Hosted Solutions
✅ **Complete automation** - Set up playlists and forget  
✅ **Production ready** - Monitoring, logging, maintenance included  
✅ **Mobile optimized** - Works great with existing apps  
✅ **Pi 5 optimized** - Efficient resource usage  
✅ **Beginner friendly** - Comprehensive documentation and scripts  

### vs. YouTube Music/Apple Music
✅ **No subscription fees** - Free after initial setup  
✅ **True offline** - Music stored locally, always available  
✅ **No DRM restrictions** - Use any device, any app  
✅ **Privacy focused** - Your data stays on your device  
✅ **Customizable** - Organize and manage however you want  

## 🚀 Ready to Get Started?

1. **[📖 Read the Setup Guide](SETUP_GUIDE.md)** for detailed instructions
2. **[⚡ Check the Quick Reference](QUICK_REFERENCE.md)** for essential commands
3. **🎵 Start building your music library!**

Transform your Raspberry Pi into a powerful music server and take control of your music experience! 🎧
