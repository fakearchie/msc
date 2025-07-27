# YouTube Download Pro - Deploy to GitHub & Pi
# PowerShell deployment script

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🚀 YouTube Download Pro - Deploy" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Git is available
try {
    $gitVersion = git --version 2>$null
    Write-Host "✅ Git detected: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Git for Windows first" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if we're in a Git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ This is not a Git repository" -ForegroundColor Red
    Write-Host "   Run this script from your msc project folder" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "📊 Current Git status:" -ForegroundColor Blue
git status --short
Write-Host ""

# Add all changes
Write-Host "📦 Adding all changes to Git..." -ForegroundColor Blue
git add .

# Commit with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "💾 Committing changes..." -ForegroundColor Blue
git commit -m "✨ YouTube Download Pro v2.0 - Modern Dark Theme & Auto-Install - $timestamp"

# Push to GitHub
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Blue
$pushResult = git push origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ SUCCESS! Ready for Pi Deployment" -ForegroundColor Green  
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. SSH into your Raspberry Pi:" -ForegroundColor White
    Write-Host "   ssh admin@YOUR_PI_IP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run the one-command setup:" -ForegroundColor White
    Write-Host "   cd /home/admin" -ForegroundColor Gray
    Write-Host "   git clone https://github.com/fakearchie/msc.git spotify-clone" -ForegroundColor Gray
    Write-Host "   cd spotify-clone" -ForegroundColor Gray
    Write-Host "   sudo ./scripts/setup-pro.sh" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Access your modern music server:" -ForegroundColor White
    Write-Host "   • Navidrome: http://YOUR_PI_IP:4533" -ForegroundColor Gray
    Write-Host "   • Downloads: http://YOUR_PI_IP:8080" -ForegroundColor Gray  
    Write-Host "   • Install Extension: http://YOUR_PI_IP:8080/install-extension" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎵 Features you'll get:" -ForegroundColor Yellow
    Write-Host "   ✅ Modern dark theme with animations" -ForegroundColor Green
    Write-Host "   ✅ Auto-IP detection (no manual config)" -ForegroundColor Green
    Write-Host "   ✅ Auto-updates from GitHub" -ForegroundColor Green
    Write-Host "   ✅ Mobile-responsive design" -ForegroundColor Green
    Write-Host "   ✅ One-click browser extension install" -ForegroundColor Green
    Write-Host "   ✅ Keyboard shortcuts and smart notifications" -ForegroundColor Green
    Write-Host ""
    Write-Host "📖 See DEPLOY_TO_PI.md for detailed instructions" -ForegroundColor Cyan
    Write-Host ""
    
    # Try to get Pi IP from user
    Write-Host "💡 Quick Setup Helper:" -ForegroundColor Yellow
    $piIP = Read-Host "Enter your Pi's IP address (or press Enter to skip)"
    
    if ($piIP -and $piIP.Trim() -ne "") {
        Write-Host ""
        Write-Host "🔗 Your custom URLs:" -ForegroundColor Yellow
        Write-Host "   • Navidrome: http://$piIP:4533" -ForegroundColor Cyan
        Write-Host "   • Downloads: http://$piIP:8080" -ForegroundColor Cyan
        Write-Host "   • Install Extension: http://$piIP:8080/install-extension" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📋 Copy this command for your Pi:" -ForegroundColor Yellow
        Write-Host "   ssh admin@$piIP" -ForegroundColor Green
        Write-Host ""
    }
    
} else {
    Write-Host ""
    Write-Host "❌ Push failed. Error details:" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "• Check your GitHub credentials" -ForegroundColor White
    Write-Host "• Verify network connection" -ForegroundColor White  
    Write-Host "• Make sure you have push access to the repository" -ForegroundColor White
    Write-Host ""
}

Read-Host "Press Enter to continue"
