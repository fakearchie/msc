# 🚀 Deploy to Raspberry Pi - Complete Guide

## 📦 What You Have Ready

Your modern YouTube Download Pro is complete with:

✅ **Modern Dark Theme** - Beautiful gradient UI with animations  
✅ **Auto-IP Detection** - No manual configuration needed  
✅ **Auto-Updates** - GitHub integration with cron jobs  
✅ **Multiple Install Methods** - Extension, bookmarklet, direct install  
✅ **Mobile Responsive** - Works on phones and tablets  
✅ **Professional Setup** - Docker containers with proper networking  

---

## 🎯 Quick Deploy (Recommended)

### **Step 1: Transfer Files to Pi**

**Option A: Direct Git Clone (Easiest)**
```bash
# On your Raspberry Pi, run:
cd /home/admin  # or /home/pi if using pi user
git clone https://github.com/fakearchie/msc.git spotify-clone
cd spotify-clone
```

**Option B: File Transfer**
```bash
# On your PC (PowerShell):
scp -r "c:\Users\taio2\downloads\msc" admin@YOUR_PI_IP:/home/admin/spotify-clone
```

### **Step 2: One-Command Setup**
```bash
# On your Raspberry Pi:
cd /home/admin/spotify-clone  # or /home/pi/spotify-clone
chmod +x scripts/setup-pro.sh
sudo ./scripts/setup-pro.sh
```

**That's it!** ✨ Your modern music server is ready!

---

## 🌐 Access Your Server

After deployment, access these URLs (replace `YOUR_PI_IP` with your Pi's IP):

- **🎵 Navidrome Music Player**: `http://YOUR_PI_IP:4533`
- **📥 Download Manager**: `http://YOUR_PI_IP:8080`
- **🔧 Extension Install Page**: `http://YOUR_PI_IP:8080/install-extension`
- **📊 Unified Dashboard**: `http://YOUR_PI_IP:8080/dashboard`

---

## 📱 Install Browser Extension

1. **Visit**: `http://YOUR_PI_IP:8080/install-extension`
2. **Install Tampermonkey** (if not already installed)
3. **Click "Install Extension"**
4. **Visit Navidrome** and enjoy the floating YouTube button! 🎵

---

## 🔄 Auto-Update Features

Your setup includes:
- ✅ **Daily auto-updates** at 2 AM from GitHub
- ✅ **Manual update command**: `./update.sh`
- ✅ **Extension auto-updates** via GitHub URLs
- ✅ **Zero maintenance** after initial setup

---

## 🎨 What's New in v2.0

### **Visual Improvements:**
- Modern dark gradient theme
- Smooth animations and transitions
- Glass-morphism effects with blur
- Professional typography and spacing
- Mobile-optimized responsive design

### **Functional Improvements:**
- Auto-detects server IP (no manual config)
- Auto-paste from clipboard for YouTube URLs
- Keyboard shortcuts (Enter/Escape)
- Enhanced error handling and notifications
- Smart notification system with icons
- Dashboard quick access button

### **Technical Improvements:**
- Auto-update capability from GitHub
- Better browser compatibility
- Improved performance and loading
- Enhanced security with HTTPS support
- Mobile device optimization

---

## 🆘 Troubleshooting

### **If deployment fails:**
```bash
# Check Docker status
sudo systemctl status docker

# Restart services
cd /home/admin/spotify-clone
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs
```

### **If extension doesn't work:**
- Ensure Tampermonkey is enabled
- Check script is active in Tampermonkey dashboard
- Verify Pi IP address is correct
- Try refreshing the Navidrome page

### **Update manually:**
```bash
cd /home/admin/spotify-clone
./update.sh
```

---

## 📋 File Structure on Pi

After deployment:
```
/home/admin/spotify-clone/
├── docker-compose.yml          # Container orchestration
├── web/                        # Flask download app
│   ├── app.py                 # Main server with auto-IP detection
│   └── templates/             # Modern UI templates
├── navidrome-integration/      # Browser extension
│   └── user-script.js         # Modern dark theme script
├── scripts/                   # Deployment scripts
│   ├── setup-pro.sh          # One-time setup
│   └── webhook-update.sh     # Auto-update handler
├── config/                    # Configuration
│   └── config.env            # Environment variables
└── update.sh                 # Manual update script
```

---

## 🎉 Success Indicators

You'll know everything works when:

1. **🌐 URLs respond:**
   - Navidrome loads at `:4533`
   - Download manager at `:8080`
   - Install page at `:8080/install-extension`

2. **🔘 Browser extension:**
   - Floating YouTube button appears in Navidrome
   - Modern dark modal opens when clicked
   - Downloads work seamlessly

3. **📱 Mobile friendly:**
   - All interfaces work on phone browsers
   - Touch targets are finger-friendly
   - Responsive design adapts to screen size

---

## 🚀 Pro Tips

### **For iPhone Users:**
- Install **Play:Sub** or **Substreamer** from App Store
- Connect using: `http://YOUR_PI_IP:4533`
- Username/Password from Navidrome settings

### **For Advanced Users:**
- Set up port forwarding for remote access
- Add SSL certificate for HTTPS
- Configure dynamic DNS for external access

### **For Automation:**
- Webhook endpoint available at `/webhook`
- Cron job handles daily updates
- Docker health checks monitor services

---

**Welcome to your modern music server! 🎵✨**

*Everything is configured for zero-maintenance operation with automatic updates and professional-grade UI.*
