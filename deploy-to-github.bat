@echo off
cls
echo ========================================
echo   🚀 YouTube Download Pro - Deploy
echo ========================================
echo.
echo This script will:
echo  1. Add all your changes to Git
echo  2. Commit them with a descriptive message
echo  3. Push to GitHub for your Pi to download
echo.

:: Check if Git is available
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git is not installed or not in PATH
    echo    Please install Git for Windows first
    pause
    exit /b 1
)

:: Check if we're in a Git repository
if not exist ".git" (
    echo ❌ This is not a Git repository
    echo    Run this script from your msc project folder
    pause
    exit /b 1
)

echo 📊 Current Git status:
git status --short
echo.

:: Add all changes
echo 📦 Adding all changes to Git...
git add .

:: Commit with timestamp
set "timestamp=%date% %time%"
echo 💾 Committing changes...
git commit -m "✨ YouTube Download Pro v2.0 - Modern Dark Theme & Auto-Install - %timestamp%"

:: Push to GitHub
echo 🚀 Pushing to GitHub...
git push origin main

if %errorlevel% eq 0 (
    echo.
    echo ========================================
    echo   ✅ SUCCESS! Ready for Pi Deployment
    echo ========================================
    echo.
    echo 🎯 Next Steps:
    echo.
    echo 1. SSH into your Raspberry Pi:
    echo    ssh admin@YOUR_PI_IP
    echo.
    echo 2. Run the one-command setup:
    echo    cd /home/admin
    echo    git clone https://github.com/fakearchie/msc.git spotify-clone
    echo    cd spotify-clone
    echo    sudo ./scripts/setup-pro.sh
    echo.
    echo 3. Access your modern music server:
    echo    • Navidrome: http://YOUR_PI_IP:4533
    echo    • Downloads: http://YOUR_PI_IP:8080
    echo    • Install Extension: http://YOUR_PI_IP:8080/install-extension
    echo.
    echo 🎵 Features you'll get:
    echo    ✅ Modern dark theme with animations
    echo    ✅ Auto-IP detection (no manual config)
    echo    ✅ Auto-updates from GitHub
    echo    ✅ Mobile-responsive design
    echo    ✅ One-click browser extension install
    echo    ✅ Keyboard shortcuts and smart notifications
    echo.
    echo 📖 See DEPLOY_TO_PI.md for detailed instructions
    echo.
) else (
    echo.
    echo ❌ Push failed. Check your GitHub credentials or network connection.
    echo.
)

echo Press any key to continue...
pause >nul
