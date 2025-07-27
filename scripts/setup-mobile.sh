#!/bin/bash

# Enhanced Music Server Setup Script
# Configures the system for better mobile app integration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the Pi's IP address
get_pi_ip() {
    hostname -I | awk '{print $1}'
}

# Generate QR code for mobile app setup
generate_qr_code() {
    local server_url="$1"
    local username="$2"
    
    print_status "Generating QR code for mobile app setup..."
    
    # Install qrencode if not present
    if ! command -v qrencode &> /dev/null; then
        print_status "Installing QR code generator..."
        sudo apt-get update && sudo apt-get install -y qrencode
    fi
    
    # Create a simple config URL (some apps support this)
    local config_text="Navidrome Server
URL: ${server_url}
Username: ${username}
Type: Subsonic"
    
    echo "$config_text" | qrencode -t ANSIUTF8
    
    print_success "Scan this QR code with your phone to copy server details!"
}

# Create mobile-friendly landing page
create_mobile_page() {
    local pi_ip="$1"
    
    cat > "/home/pi/spotify-clone/web/templates/mobile-setup.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mobile Setup - Music Server</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: #f5f5f5; 
        }
        .container { 
            max-width: 600px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 12px; 
            padding: 30px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
        }
        .app-link { 
            display: block; 
            margin: 15px 0; 
            padding: 15px; 
            background: #007AFF; 
            color: white; 
            text-decoration: none; 
            border-radius: 8px; 
            text-align: center; 
            font-weight: 500; 
        }
        .config-box { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin: 20px 0; 
            font-family: monospace; 
        }
        .copy-btn { 
            background: #28a745; 
            color: white; 
            border: none; 
            padding: 10px 15px; 
            border-radius: 5px; 
            cursor: pointer; 
            margin-left: 10px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📱 Mobile App Setup</h1>
        
        <h2>Recommended Apps:</h2>
        
        <h3>iPhone:</h3>
        <a href="https://apps.apple.com/app/play-sub/id955329386" class="app-link" target="_blank">
            📱 Play:Sub ($4.99) - Recommended
        </a>
        <a href="https://apps.apple.com/app/substreamer/id1012991665" class="app-link" target="_blank">
            📱 Substreamer ($4.99)
        </a>
        <a href="https://apps.apple.com/app/isub/id362920532" class="app-link" target="_blank">
            📱 iSub (Free)
        </a>
        
        <h3>Android:</h3>
        <a href="https://play.google.com/store/apps/details?id=github.daneren2005.dsub" class="app-link" target="_blank">
            🤖 DSub (Free) - Recommended
        </a>
        <a href="https://play.google.com/store/apps/details?id=net.sourceforge.subsonic.androidapp" class="app-link" target="_blank">
            🤖 Substreamer ($4.99)
        </a>
        
        <h2>Server Configuration:</h2>
        <div class="config-box">
            <strong>Server URL:</strong> http://PI_IP_PLACEHOLDER:4533
            <button class="copy-btn" onclick="copyToClipboard('http://PI_IP_PLACEHOLDER:4533')">Copy</button><br><br>
            
            <strong>Username:</strong> admin
            <button class="copy-btn" onclick="copyToClipboard('admin')">Copy</button><br><br>
            
            <strong>Password:</strong> (Check your config.env file)
            <button class="copy-btn" onclick="copyToClipboard('$(grep ADMIN_PASSWORD /home/pi/spotify-clone/config/config.env | cut -d= -f2)')">Copy</button><br><br>
            
            <strong>Server Type:</strong> Subsonic/Navidrome
        </div>
        
        <h2>Quick Links:</h2>
        <a href="/" class="app-link">⬇️ Download Music</a>
        <a href="http://PI_IP_PLACEHOLDER:4533" class="app-link" target="_blank">🎵 Web Player</a>
        <a href="/dashboard" class="app-link">📊 Dashboard</a>
    </div>
    
    <script>
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(() => {
                alert('Copied to clipboard!');
            });
        }
        
        // Replace placeholder with actual IP
        const actualIP = window.location.hostname;
        document.body.innerHTML = document.body.innerHTML.replace(/PI_IP_PLACEHOLDER/g, actualIP);
    </script>
</body>
</html>
EOF
    
    print_success "Mobile setup page created!"
}

# Add route for mobile setup page
add_mobile_route() {
    local app_py="/home/pi/spotify-clone/web/app.py"
    
    if ! grep -q "mobile-setup" "$app_py"; then
        print_status "Adding mobile setup route..."
        
        # Add the route before the main function
        sed -i '/if __name__ == .__main__.:/i\
@app.route("/mobile-setup")\
def mobile_setup():\
    """Mobile app setup instructions"""\
    return render_template("mobile-setup.html")\
\
' "$app_py"
        
        print_success "Mobile setup route added!"
    fi
}

# Update nginx config for better mobile support
update_nginx_config() {
    local nginx_conf="/home/pi/spotify-clone/config/nginx.conf"
    
    if [ -f "$nginx_conf" ]; then
        print_status "Updating Nginx configuration for mobile optimization..."
        
        # Backup original
        cp "$nginx_conf" "${nginx_conf}.backup"
        
        cat > "$nginx_conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Gzip compression for better mobile performance
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    # Mobile-friendly headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    upstream navidrome {
        server navidrome:4533;
    }
    
    upstream downloader {
        server youtube_downloader:80;
    }
    
    server {
        listen 80;
        server_name _;
        
        # Mobile detection and redirect
        set $mobile_rewrite do_not_perform;
        
        if ($http_user_agent ~* "(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino") {
            set $mobile_rewrite perform;
        }
        
        # Main music player (Navidrome)
        location / {
            proxy_pass http://navidrome;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support for real-time updates
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
        
        # Download interface
        location /download/ {
            rewrite ^/download/(.*) /$1 break;
            proxy_pass http://downloader;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Mobile setup page
        location /mobile {
            proxy_pass http://downloader/mobile-setup;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # Dashboard
        location /dashboard {
            proxy_pass http://downloader/dashboard;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # API endpoints
        location /api/ {
            proxy_pass http://navidrome;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # Static files with caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            proxy_pass http://navidrome;
        }
    }
}
EOF
        
        print_success "Nginx configuration updated for mobile optimization!"
    fi
}

# Main setup function
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Enhanced Mobile Music Server Setup  ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo
    
    local pi_ip=$(get_pi_ip)
    print_status "Pi IP Address: $pi_ip"
    
    # Create mobile setup page
    create_mobile_page "$pi_ip"
    
    # Add mobile route to Flask app
    add_mobile_route
    
    # Update nginx configuration
    update_nginx_config
    
    # Generate QR code
    generate_qr_code "http://$pi_ip:4533" "admin"
    
    echo
    print_success "Mobile setup completed!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your services: ./scripts/music-server.sh restart"
    echo "2. Visit http://$pi_ip/mobile on your phone for setup instructions"
    echo "3. Download a mobile app and configure it with the server details"
    echo "4. Visit http://$pi_ip/dashboard for the unified interface"
    echo
    echo -e "${YELLOW}Mobile app configuration:${NC}"
    echo "Server: http://$pi_ip:4533"
    echo "Username: admin"
    echo "Password: (check your config.env file)"
    echo "Type: Subsonic/Navidrome"
    echo
    print_success "Happy listening! 🎵"
}

# Run main function
main "$@"
