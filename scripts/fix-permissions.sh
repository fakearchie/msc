#!/bin/bash

# Quick Fix Script for Permission Issues
# Run this if you get permission errors during installation

echo "🔧 Fixing permissions for music server..."

# Create music directory with proper permissions
echo "Creating music directories..."
sudo mkdir -p /home/pi/music/{downloads,library}
sudo chown -R pi:pi /home/pi/music
sudo chmod -R 755 /home/pi/music

# Fix project directory permissions if needed
if [ -d "/home/pi/spotify-clone" ]; then
    echo "Fixing project directory permissions..."
    sudo chown -R pi:pi /home/pi/spotify-clone
    chmod -R 755 /home/pi/spotify-clone
fi

# Make scripts executable
if [ -d "/home/pi/spotify-clone/scripts" ]; then
    echo "Making scripts executable..."
    chmod +x /home/pi/spotify-clone/scripts/*.sh
fi

# Check Docker group membership
if ! groups $USER | grep -q docker; then
    echo "Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "⚠️  You need to log out and back in for Docker group changes to take effect"
fi

echo "✅ Permissions fixed! You can now run:"
echo "   cd /home/pi/spotify-clone"
echo "   ./scripts/install.sh"
echo ""
echo "If Docker group was added, log out and back in first."
