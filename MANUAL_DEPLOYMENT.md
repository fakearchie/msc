# Manual Deployment Guide for Raspberry Pi 5

## 🚀 Step-by-Step Manual Deployment

### 1. Connect to Your Pi

```bash
# SSH into your Pi (replace with your Pi's IP)
ssh pi@YOUR_PI_IP

# Navigate to your project directory
cd /home/pi/spotify-clone
```

### 2. Create Required Directories

```bash
# Create new directories for enhancements
sudo mkdir -p navidrome-integration
sudo mkdir -p docs
sudo mkdir -p web/templates
```

### 3. Create the User Script File

```bash
# Create the browser integration script
sudo nano navidrome-integration/user-script.js
```

**Copy and paste this content:**
```javascript
// Navidrome YouTube Download Integration User Script
// Install this with Tampermonkey or Greasemonkey browser extension

// ==UserScript==
// @name         Navidrome YouTube Download Integration
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Add YouTube download button to Navidrome interface
// @author       You
// @match        http://*/navidrome/*
// @match        http://*:4533/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    
    // Configuration - Update with your Pi's IP
    const DOWNLOAD_SERVER = window.location.hostname + ':8080';
    
    // Add YouTube download button to Navidrome interface
    function addDownloadButton() {
        // Create download button
        const downloadBtn = document.createElement('button');
        downloadBtn.innerHTML = '🎵 Download from YouTube';
        downloadBtn.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 9999;
            background: #2196F3;
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        `;
        
        downloadBtn.onclick = function() {
            showDownloadModal();
        };
        
        document.body.appendChild(downloadBtn);
    }
    
    // Show download modal
    function showDownloadModal() {
        const modal = document.createElement('div');
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 10000;
            display: flex;
            align-items: center;
            justify-content: center;
        `;
        
        const content = document.createElement('div');
        content.style.cssText = `
            background: white;
            padding: 30px;
            border-radius: 10px;
            max-width: 500px;
            width: 90%;
        `;
        
        content.innerHTML = `
            <h3 style="margin-bottom: 20px;">Download from YouTube</h3>
            <input type="text" id="youtube-url" placeholder="Paste YouTube URL here..." 
                   style="width: 100%; padding: 10px; margin-bottom: 15px; border: 1px solid #ddd; border-radius: 4px;">
            <div style="text-align: right;">
                <button onclick="this.closest('.modal').remove()" 
                        style="margin-right: 10px; padding: 8px 15px; background: #ccc; border: none; border-radius: 4px;">Cancel</button>
                <button onclick="submitDownload()" 
                        style="padding: 8px 15px; background: #2196F3; color: white; border: none; border-radius: 4px;">Download</button>
            </div>
        `;
        
        modal.className = 'modal';
        modal.appendChild(content);
        document.body.appendChild(modal);
        
        // Focus the input
        document.getElementById('youtube-url').focus();
        
        // Close on outside click
        modal.onclick = function(e) {
            if (e.target === modal) {
                modal.remove();
            }
        };
    }
    
    // Submit download to your server
    window.submitDownload = function() {
        const url = document.getElementById('youtube-url').value;
        if (!url) {
            alert('Please enter a YouTube URL');
            return;
        }
        
        // Open download interface in new tab
        window.open(`http://${DOWNLOAD_SERVER}/?url=${encodeURIComponent(url)}`, '_blank');
        
        // Close modal
        document.querySelector('.modal').remove();
        
        // Show success message
        const notification = document.createElement('div');
        notification.innerHTML = 'Download started! Check the Downloads tab.';
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: #4CAF50;
            color: white;
            padding: 10px 20px;
            border-radius: 4px;
            z-index: 10001;
        `;
        document.body.appendChild(notification);
        
        setTimeout(() => notification.remove(), 3000);
    };
    
    // Wait for page to load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', addDownloadButton);
    } else {
        addDownloadButton();
    }
})();
```

### 4. Update Flask Application

```bash
# Backup the original Flask app
sudo cp web/app.py web/app.py.backup

# Edit the Flask app to add new routes
sudo nano web/app.py
```

**Add these routes before the `if __name__ == '__main__':` line:**

```python
@app.route('/mobile-setup')
def mobile_setup():
    """Mobile app setup instructions"""
    return render_template('mobile-setup.html')

@app.route('/dashboard')
def dashboard():
    """Unified dashboard page"""
    return render_template('dashboard.html')
```

**Also update the index route to support URL prefilling:**

Find this line:
```python
def index():
    """Main page with download form"""
    return render_template('index.html')
```

Replace with:
```python
def index():
    """Main page with download form"""
    # Pre-fill URL if provided as query parameter
    url = request.args.get('url', '')
    return render_template('index.html', prefill_url=url)
```

### 5. Update the HTML Template

```bash
# Edit the index template
sudo nano web/templates/index.html
```

**Find the input field and add the value attribute:**

Find this section:
```html
<input 
    type="url" 
    id="url" 
    name="url" 
    placeholder="https://www.youtube.com/watch?v=..." 
    required
    autocomplete="off"
>
```

Replace with:
```html
<input 
    type="url" 
    id="url" 
    name="url" 
    placeholder="https://www.youtube.com/watch?v=..." 
    required
    autocomplete="off"
    value="{{ prefill_url or '' }}"
>
```

### 6. Create New Template Files

```bash
# Create the dashboard template
sudo nano web/templates/dashboard.html
```

**Paste the dashboard HTML content** (see the full dashboard.html file created earlier)

```bash
# Create the mobile setup template  
sudo nano web/templates/mobile-setup.html
```

**Paste the mobile setup HTML content** (see the mobile-setup.html template)

### 7. Create Enhanced Setup Script

```bash
# Create the mobile setup script
sudo nano scripts/setup-mobile.sh

# Make it executable
sudo chmod +x scripts/setup-mobile.sh
```

**Paste the setup script content** (see the setup-mobile.sh file created earlier)

### 8. Set Proper Permissions

```bash
# Fix ownership and permissions
sudo chown -R pi:pi /home/pi/spotify-clone
sudo chmod -R 755 /home/pi/spotify-clone
sudo chmod +x scripts/*.sh
```

### 9. Run the Enhanced Setup

```bash
# Run the mobile setup enhancement
./scripts/setup-mobile.sh

# Restart all services
./scripts/music-server.sh restart
```

### 10. Test the New Features

```bash
# Get your Pi's IP address
hostname -I | awk '{print $1}'
```

**Then test these URLs in your browser:**
- Dashboard: `http://YOUR_PI_IP/dashboard`
- Mobile Setup: `http://YOUR_PI_IP/mobile`
- Music Player: `http://YOUR_PI_IP:4533`
- Downloads: `http://YOUR_PI_IP:8080`

## ✅ Verification Steps

1. **Check services are running:**
   ```bash
   docker ps
   ```

2. **Check logs for errors:**
   ```bash
   docker-compose logs
   ```

3. **Test the dashboard:**
   ```bash
   curl -I http://localhost/dashboard
   ```

4. **Test mobile setup page:**
   ```bash
   curl -I http://localhost:8080/mobile-setup
   ```

## 🔧 Troubleshooting

**If services won't start:**
```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker if needed
sudo systemctl restart docker

# Restart your music server
./scripts/music-server.sh restart
```

**If templates don't load:**
```bash
# Check Flask app syntax
python3 -m py_compile web/app.py

# Check file permissions
ls -la web/templates/
```

**If Nginx isn't working:**
```bash
# Check Nginx container
docker logs music_proxy

# Restart just Nginx
docker-compose restart nginx
```

This manual method gives you full control over each step and helps you understand what's being deployed!
