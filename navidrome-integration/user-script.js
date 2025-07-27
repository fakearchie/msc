// Navidrome YouTube Download Integration - Modern Dark Theme
// Install this with Tampermonkey or Greasemonkey browser extension

// ==UserScript==
// @name         Navidrome YouTube Download Pro
// @namespace    http://tampermonkey.net/
// @version      2.0
// @description  Modern dark-themed YouTube download integration for Navidrome
// @author       MusicServer
// @match        http://*/navidrome/*
// @match        http://*:4533/*
// @match        https://*/navidrome/*
// @match        https://*:4533/*
// @grant        none
// @updateURL    https://raw.githubusercontent.com/fakearchie/msc/main/navidrome-integration/user-script.js
// @downloadURL  https://raw.githubusercontent.com/fakearchie/msc/main/navidrome-integration/user-script.js
// ==/UserScript==

(function() {
    'use strict';
    
    // Configuration - Auto-detects your server
    const DOWNLOAD_SERVER = window.location.hostname + ':8080';
    const DASHBOARD_URL = `http://${window.location.hostname}/dashboard`;
    
    // Add modern dark-themed download button
    function addDownloadButton() {
        // Check if button already exists
        if (document.getElementById('yt-download-btn')) return;
        
        // Create floating action button with modern design
        const downloadBtn = document.createElement('button');
        downloadBtn.id = 'yt-download-btn';
        downloadBtn.innerHTML = `
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="7,10 12,15 17,10"/>
                <line x1="12" y1="15" x2="12" y2="3"/>
            </svg>
            <span style="margin-left: 8px;">YouTube</span>
        `;
        
        downloadBtn.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 10000;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 50px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
            backdrop-filter: blur(10px);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            display: flex;
            align-items: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            letter-spacing: 0.5px;
        `;
        
        // Hover effects
        downloadBtn.addEventListener('mouseenter', () => {
            downloadBtn.style.transform = 'translateY(-2px) scale(1.05)';
            downloadBtn.style.boxShadow = '0 12px 40px rgba(102, 126, 234, 0.4)';
        });
        
        downloadBtn.addEventListener('mouseleave', () => {
            downloadBtn.style.transform = 'translateY(0) scale(1)';
            downloadBtn.style.boxShadow = '0 8px 32px rgba(102, 126, 234, 0.3)';
        });
        
        downloadBtn.onclick = function() {
            showDownloadModal();
        };
        
        document.body.appendChild(downloadBtn);
        
        // Add dashboard button
        addDashboardButton();
    }
    
    // Add dashboard access button
    function addDashboardButton() {
        if (document.getElementById('dashboard-btn')) return;
        
        const dashboardBtn = document.createElement('button');
        dashboardBtn.id = 'dashboard-btn';
        dashboardBtn.innerHTML = `
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="9"/>
                <rect x="14" y="3" width="7" height="5"/>
                <rect x="14" y="12" width="7" height="9"/>
                <rect x="3" y="16" width="7" height="5"/>
            </svg>
        `;
        
        dashboardBtn.style.cssText = `
            position: fixed;
            top: 80px;
            right: 20px;
            z-index: 10000;
            background: rgba(255, 255, 255, 0.1);
            color: white;
            border: 1px solid rgba(255, 255, 255, 0.2);
            padding: 12px;
            border-radius: 50%;
            cursor: pointer;
            width: 48px;
            height: 48px;
            backdrop-filter: blur(10px);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            display: flex;
            align-items: center;
            justify-content: center;
        `;
        
        dashboardBtn.addEventListener('mouseenter', () => {
            dashboardBtn.style.background = 'rgba(255, 255, 255, 0.2)';
            dashboardBtn.style.transform = 'scale(1.1)';
        });
        
        dashboardBtn.addEventListener('mouseleave', () => {
            dashboardBtn.style.background = 'rgba(255, 255, 255, 0.1)';
            dashboardBtn.style.transform = 'scale(1)';
        });
        
        dashboardBtn.onclick = function() {
            window.open(DASHBOARD_URL, '_blank');
        };
        
        document.body.appendChild(dashboardBtn);
    }
    
    
    // Show modern dark-themed download modal
    function showDownloadModal() {
        // Remove existing modal if any
        const existingModal = document.querySelector('.yt-download-modal');
        if (existingModal) existingModal.remove();
        
        const modal = document.createElement('div');
        modal.className = 'yt-download-modal';
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(10px);
            z-index: 10001;
            display: flex;
            align-items: center;
            justify-content: center;
            animation: fadeIn 0.3s ease-out;
        `;
        
        const content = document.createElement('div');
        content.style.cssText = `
            background: linear-gradient(145deg, #1e1e2e, #262640);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            max-width: 500px;
            width: 90%;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
            animation: slideUp 0.3s ease-out;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        `;
        
        content.innerHTML = `
            <style>
                @keyframes fadeIn {
                    from { opacity: 0; }
                    to { opacity: 1; }
                }
                @keyframes slideUp {
                    from { transform: translateY(30px); opacity: 0; }
                    to { transform: translateY(0); opacity: 1; }
                }
                .yt-input {
                    background: rgba(255, 255, 255, 0.1);
                    border: 2px solid rgba(255, 255, 255, 0.2);
                    color: white;
                    transition: all 0.3s ease;
                }
                .yt-input:focus {
                    outline: none;
                    border-color: #667eea;
                    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.3);
                    background: rgba(255, 255, 255, 0.15);
                }
                .yt-btn {
                    transition: all 0.3s ease;
                    font-weight: 600;
                    letter-spacing: 0.5px;
                }
                .yt-btn:hover {
                    transform: translateY(-2px);
                }
                .yt-btn-primary {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
                }
                .yt-btn-primary:hover {
                    box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
                }
                .yt-btn-secondary {
                    background: rgba(255, 255, 255, 0.1);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                }
                .yt-btn-secondary:hover {
                    background: rgba(255, 255, 255, 0.2);
                }
            </style>
            
            <div style="text-align: center; margin-bottom: 30px;">
                <div style="width: 60px; height: 60px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px;">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="white">
                        <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                    </svg>
                </div>
                <h3 style="color: white; margin: 0; font-size: 24px; font-weight: 700;">Download from YouTube</h3>
                <p style="color: rgba(255, 255, 255, 0.7); margin: 10px 0 0; font-size: 14px;">Add music to your library instantly</p>
            </div>
            
            <div style="margin-bottom: 25px;">
                <input 
                    type="text" 
                    id="youtube-url" 
                    placeholder="Paste YouTube URL or search term..." 
                    class="yt-input"
                    style="width: 100%; padding: 16px 20px; border-radius: 12px; font-size: 16px; box-sizing: border-box;"
                >
            </div>
            
            <div style="display: flex; gap: 12px; justify-content: flex-end;">
                <button 
                    onclick="document.querySelector('.yt-download-modal').remove()" 
                    class="yt-btn yt-btn-secondary"
                    style="padding: 12px 24px; border: none; border-radius: 10px; cursor: pointer; color: white; font-size: 14px;"
                >
                    Cancel
                </button>
                <button 
                    onclick="submitDownload()" 
                    class="yt-btn yt-btn-primary"
                    style="padding: 12px 24px; border: none; border-radius: 10px; cursor: pointer; color: white; font-size: 14px;"
                >
                    Download Now
                </button>
            </div>
            
            <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid rgba(255, 255, 255, 0.1);">
                <p style="color: rgba(255, 255, 255, 0.5); font-size: 12px; margin: 0; text-align: center;">
                    Supports: Videos • Playlists • Music • Channels
                </p>
            </div>
        `;
        
        modal.appendChild(content);
        document.body.appendChild(modal);
        
        // Focus the input
        const input = document.getElementById('youtube-url');
        input.focus();
        
        // Handle keyboard shortcuts
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                submitDownload();
            } else if (e.key === 'Escape') {
                modal.remove();
            }
        });
        
        // Close on outside click
        modal.onclick = function(e) {
            if (e.target === modal) {
                modal.remove();
            }
        };
        
        // Auto-paste if clipboard contains YouTube URL
        if (navigator.clipboard && navigator.clipboard.readText) {
            navigator.clipboard.readText().then(text => {
                if (text && (text.includes('youtube.com') || text.includes('youtu.be'))) {
                    input.value = text;
                    input.select();
                }
            }).catch(() => {});
        }
    }
    
    
    // Enhanced download submission with modern notifications
    window.submitDownload = function() {
        const input = document.getElementById('youtube-url');
        const url = input.value.trim();
        
        if (!url) {
            showNotification('Please enter a YouTube URL or search term', 'error');
            input.focus();
            return;
        }
        
        // Show loading state
        showNotification('Starting download...', 'loading');
        
        // Open download interface
        const downloadUrl = `http://${DOWNLOAD_SERVER}/?url=${encodeURIComponent(url)}`;
        window.open(downloadUrl, '_blank');
        
        // Close modal
        document.querySelector('.yt-download-modal').remove();
        
        // Show success notification after a delay
        setTimeout(() => {
            showNotification('Download started! Check the Downloads page for progress.', 'success');
        }, 1000);
    };
    
    // Modern notification system
    function showNotification(message, type = 'info') {
        // Remove existing notifications
        const existing = document.querySelectorAll('.yt-notification');
        existing.forEach(el => el.remove());
        
        const notification = document.createElement('div');
        notification.className = 'yt-notification';
        
        const colors = {
            success: { bg: 'rgba(34, 197, 94, 0.9)', border: '#22c55e' },
            error: { bg: 'rgba(239, 68, 68, 0.9)', border: '#ef4444' },
            loading: { bg: 'rgba(59, 130, 246, 0.9)', border: '#3b82f6' },
            info: { bg: 'rgba(107, 114, 128, 0.9)', border: '#6b7280' }
        };
        
        const color = colors[type] || colors.info;
        
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: ${color.bg};
            color: white;
            padding: 16px 24px;
            border-radius: 50px;
            z-index: 10002;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            font-weight: 500;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
            backdrop-filter: blur(10px);
            border: 2px solid ${color.border};
            animation: slideDown 0.3s ease-out;
            max-width: 400px;
            text-align: center;
            display: flex;
            align-items: center;
            gap: 10px;
        `;
        
        // Add icon based on type
        const icons = {
            success: '✅',
            error: '❌',
            loading: '⏳',
            info: 'ℹ️'
        };
        
        notification.innerHTML = `
            <style>
                @keyframes slideDown {
                    from { transform: translateX(-50%) translateY(-20px); opacity: 0; }
                    to { transform: translateX(-50%) translateY(0); opacity: 1; }
                }
                @keyframes slideUp {
                    from { transform: translateX(-50%) translateY(0); opacity: 1; }
                    to { transform: translateX(-50%) translateY(-20px); opacity: 0; }
                }
            </style>
            <span style="font-size: 16px;">${icons[type] || icons.info}</span>
            <span>${message}</span>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after delay (except loading)
        if (type !== 'loading') {
            setTimeout(() => {
                notification.style.animation = 'slideUp 0.3s ease-out';
                setTimeout(() => notification.remove(), 300);
            }, type === 'error' ? 5000 : 3000);
        }
    }
    
    // Initialize on page load with better detection
    function initialize() {
        // Wait for page to be fully loaded
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initialize);
            return;
        }
        
        // Add buttons with a slight delay to ensure page is ready
        setTimeout(() => {
            addDownloadButton();
            
            // Show welcome notification on first load
            if (!sessionStorage.getItem('yt-script-loaded')) {
                sessionStorage.setItem('yt-script-loaded', 'true');
                setTimeout(() => {
                    showNotification('YouTube Download Pro loaded! Click the button to get started.', 'success');
                }, 1000);
            }
        }, 500);
        
        // Re-add buttons if they disappear (for SPA navigation)
        const observer = new MutationObserver(() => {
            if (!document.getElementById('yt-download-btn')) {
                setTimeout(addDownloadButton, 100);
            }
        });
        
        observer.observe(document.body, { 
            childList: true, 
            subtree: true 
        });
    }
    
    // Start initialization
    initialize();
    
})();
