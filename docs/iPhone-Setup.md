# iPhone Apps Setup Guide

## 📱 Setting up iPhone Apps with Your Music Server

### App Configuration Settings:

**Server URL**: `http://YOUR_PI_IP:4533`
**Username**: Your Navidrome username (default: admin)
**Password**: Your Navidrome password (from config.env)
**Server Type**: Subsonic/Navidrome

### Step-by-Step Setup:

#### For Play:Sub:
1. Download Play:Sub from App Store ($4.99)
2. Open app and tap "Add Server"
3. Enter server details:
   - Name: "My Music Server"
   - Server: `http://YOUR_PI_IP:4533`
   - Username: `admin` (or your username)
   - Password: (your password from config.env)
4. Tap "Save" and "Test Connection"
5. Browse your music library!

#### For Substreamer:
1. Download Substreamer from App Store ($4.99)
2. Tap "+" to add new server
3. Select "Subsonic/Navidrome"
4. Enter same server details as above
5. Test connection and start streaming

#### For iSub (Free):
1. Download iSub from App Store
2. Go to Settings > Servers
3. Add New Server with same details
4. Basic interface but fully functional

### Features You'll Get:

✅ **Stream your entire library** from anywhere
✅ **Download for offline** listening (like Spotify Premium)
✅ **Create playlists** and sync across devices
✅ **Background playback** and lock screen controls
✅ **AirPlay support** for wireless streaming
✅ **Search** your entire music collection
✅ **Gapless playback** for albums
✅ **High quality audio** streaming

### Pro Tips:

1. **Enable Downloads**: In app settings, enable downloading for offline listening
2. **Quality Settings**: Set to highest quality for best audio
3. **Cache Size**: Increase cache size for better performance
4. **Background Refresh**: Enable for automatic library updates
5. **Cellular Data**: Configure data usage preferences

### Troubleshooting:

**Can't connect?**
- Ensure your Pi is on the same network
- Check if port 4533 is accessible
- Try using Pi's IP address instead of hostname

**No music showing?**
- Check if Navidrome has scanned your music folder
- Verify music files are in supported formats (MP3, FLAC, etc.)
- Trigger a library scan: `docker exec navidrome /app/navidrome --scan`

**Slow loading?**
- Check your Pi's performance with `htop`
- Reduce image quality in Navidrome settings
- Ensure good WiFi connection

### Network Access:

#### Local Network Only:
Use your Pi's local IP address (e.g., `192.168.1.100:4533`)

#### Internet Access (Advanced):
Set up port forwarding on your router:
- Forward port 4533 to your Pi
- Use your public IP or domain name
- Consider setting up HTTPS for security

### Security Notes:

1. **Change default password** in config.env
2. **Use strong passwords** for user accounts
3. **Consider VPN access** instead of port forwarding
4. **Regular updates** of all components
