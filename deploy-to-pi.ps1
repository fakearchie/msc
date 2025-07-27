# PowerShell script to deploy enhancements to Raspberry Pi
# Run this from your Windows machine

param(
    [Parameter(Mandatory=$true)]
    [string]$PiIP,
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "pi"
)

Write-Host "🚀 Deploying Music Server Enhancements to Raspberry Pi" -ForegroundColor Blue
Write-Host "Target: $PiUser@$PiIP" -ForegroundColor Green

# Check if we can reach the Pi
Write-Host "Testing connection to Pi..." -ForegroundColor Yellow
$pingResult = Test-Connection -ComputerName $PiIP -Count 2 -Quiet
if (-not $pingResult) {
    Write-Host "❌ Cannot reach Pi at $PiIP. Please check the IP address and network connection." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Pi is reachable!" -ForegroundColor Green

# Create a temporary directory for files
$tempDir = Join-Path $env:TEMP "msc-deploy"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "📦 Preparing files for deployment..." -ForegroundColor Yellow

# Copy files to temp directory
$sourceDir = $PSScriptRoot
$filesToCopy = @(
    "navidrome-integration\user-script.js",
    "web\templates\dashboard.html",
    "web\templates\mobile-setup.html", 
    "scripts\setup-mobile.sh",
    "docs\iPhone-Setup.md",
    "ENHANCEMENT_SUMMARY.md"
)

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $sourceDir $file
    $destPath = Join-Path $tempDir $file
    
    if (Test-Path $sourcePath) {
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $sourcePath $destPath
        Write-Host "📄 Prepared: $file" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  File not found: $file" -ForegroundColor Yellow
    }
}

# Create deployment script for Pi
$deployScript = @"
#!/bin/bash
echo "🎵 Deploying Music Server Enhancements..."

# Navigate to project directory
cd /home/pi/spotify-clone || {
    echo "❌ Project directory not found. Make sure your music server is installed."
    exit 1
}

# Backup existing files
echo "📦 Creating backup..."
sudo cp -r web/templates web/templates.backup.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sudo cp -r scripts scripts.backup.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Copy new files
echo "📁 Installing new files..."
sudo mkdir -p navidrome-integration docs
sudo cp ~/msc-deploy/navidrome-integration/user-script.js navidrome-integration/ 2>/dev/null || true
sudo cp ~/msc-deploy/web/templates/dashboard.html web/templates/ 2>/dev/null || true
sudo cp ~/msc-deploy/web/templates/mobile-setup.html web/templates/ 2>/dev/null || true
sudo cp ~/msc-deploy/scripts/setup-mobile.sh scripts/ 2>/dev/null || true
sudo cp ~/msc-deploy/docs/iPhone-Setup.md docs/ 2>/dev/null || true
sudo cp ~/msc-deploy/ENHANCEMENT_SUMMARY.md . 2>/dev/null || true

# Make scripts executable
sudo chmod +x scripts/setup-mobile.sh

# Update Flask app with new routes
echo "🔧 Updating Flask application..."
if ! grep -q "mobile-setup" web/app.py; then
    sudo sed -i '/if __name__ == .__main__.:/i\
@app.route("/mobile-setup")\
def mobile_setup():\
    """Mobile app setup instructions"""\
    return render_template("mobile-setup.html")\
\
@app.route("/dashboard")\
def dashboard():\
    """Unified dashboard page"""\
    return render_template("dashboard.html")\
' web/app.py
fi

# Update index route to support URL prefilling
if ! grep -q "prefill_url" web/app.py; then
    sudo sed -i 's/return render_template(.index.html.)/# Pre-fill URL if provided as query parameter\n    url = request.args.get("url", "")\n    return render_template("index.html", prefill_url=url)/' web/app.py
fi

# Update index.html template
if ! grep -q "prefill_url" web/templates/index.html; then
    sudo sed -i 's/required/required\n                    value="{{ prefill_url or '\'\''\' }}"/' web/templates/index.html
fi

# Set proper permissions
sudo chown -R pi:pi /home/pi/spotify-clone
sudo chmod -R 755 /home/pi/spotify-clone

echo "✅ Files deployed successfully!"
echo ""
echo "🚀 Next steps:"
echo "1. Run enhanced mobile setup: ./scripts/setup-mobile.sh"
echo "2. Restart services: ./scripts/music-server.sh restart"
echo "3. Test new features:"
echo "   - Dashboard: http://\$(hostname -I | awk '{print \$1}')/dashboard"
echo "   - Mobile setup: http://\$(hostname -I | awk '{print \$1}')/mobile"
echo ""
echo "📱 For iPhone apps:"
echo "   - Download Play:Sub (\$4.99) from App Store"
echo "   - Configure with server: http://\$(hostname -I | awk '{print \$1}'):4533"
echo ""
echo "🎵 Enhancement deployment complete!"

# Clean up
rm -rf ~/msc-deploy
"@

$deployScript | Out-File -FilePath (Join-Path $tempDir "deploy.sh") -Encoding UTF8

Write-Host "🔧 Created deployment script" -ForegroundColor Green

# Display instructions
Write-Host ""
Write-Host "📋 DEPLOYMENT INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Copy the files to your Pi using SCP/SFTP:" -ForegroundColor White
Write-Host "   scp -r `"$tempDir`" $PiUser@${PiIP}:~/msc-deploy" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. SSH into your Pi:" -ForegroundColor White  
Write-Host "   ssh $PiUser@$PiIP" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Run the deployment script:" -ForegroundColor White
Write-Host "   chmod +x ~/msc-deploy/deploy.sh" -ForegroundColor Yellow
Write-Host "   ~/msc-deploy/deploy.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Alternative: Run the commands below to do it all at once!" -ForegroundColor Green
Write-Host ""

# Create one-liner commands
Write-Host "📋 COPY & PASTE THESE COMMANDS:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Copy files to Pi (run from Windows):" -ForegroundColor Gray
Write-Host "scp -r `"$tempDir`" $PiUser@${PiIP}:~/msc-deploy" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Deploy on Pi (run after SSH into Pi):" -ForegroundColor Gray
Write-Host "chmod +x ~/msc-deploy/deploy.sh && ~/msc-deploy/deploy.sh" -ForegroundColor Yellow
Write-Host ""

Write-Host "✅ Deployment package ready in: $tempDir" -ForegroundColor Green
Write-Host ""
Write-Host "🔗 After deployment, access your enhanced music server at:" -ForegroundColor Cyan
Write-Host "   Dashboard: http://$PiIP/dashboard" -ForegroundColor Yellow
Write-Host "   Mobile Setup: http://$PiIP/mobile" -ForegroundColor Yellow
Write-Host "   Music Player: http://$PiIP:4533" -ForegroundColor Yellow
Write-Host "   Downloads: http://$PiIP:8080" -ForegroundColor Yellow
