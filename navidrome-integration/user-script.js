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
