@echo off
echo ========================================
echo 🚀 YouTube Download Pro v2.0 Deployment
echo ========================================
echo.

echo 📤 Step 1: Pushing changes to GitHub...
git add .
git commit -m "✨ YouTube Download Pro v2.0 - Modern dark theme with auto-updates"
git push origin main

if %errorlevel% equ 0 (
    echo ✅ Successfully pushed to GitHub!
    echo.
    echo 📱 Step 2: Deploy to your Raspberry Pi
    echo.
    echo Copy and run this command on your Pi:
    echo.
    echo curl -sSL https://raw.githubusercontent.com/fakearchie/msc/main/scripts/setup-pro.sh ^| bash
    echo.
    echo OR if you already have the project:
    echo.
    echo curl -sSL https://raw.githubusercontent.com/fakearchie/msc/main/upgrade-to-v2.sh ^| bash
    echo.
    echo 🎉 Then visit: http://YOUR_PI_IP:8080/install-extension
    echo.
) else (
    echo ❌ Git push failed. Make sure you're authenticated.
    echo.
    echo 🔧 Try running these commands manually:
    echo   git add .
    echo   git commit -m "✨ YouTube Download Pro v2.0"
    echo   git push origin main
)

pause
