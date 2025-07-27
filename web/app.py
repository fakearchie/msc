#!/usr/bin/env python3
"""
YouTube Music Downloader Web Interface
Provides a simple web form to download music from YouTube URLs
"""

import os
import json
import subprocess
import logging
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from werkzeug.utils import secure_filename
import re

# Configuration
app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-change-this')

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/web.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configuration from environment
DOWNLOAD_PATH = os.environ.get('DOWNLOAD_PATH', '/downloads')
MAX_DOWNLOAD_SIZE = int(os.environ.get('MAX_DOWNLOAD_SIZE', '100'))  # MB
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')

# Global download status storage (in production, use Redis or database)
download_status = {}

def is_valid_youtube_url(url):
    """Check if URL is a valid YouTube URL"""
    youtube_patterns = [
        r'https?://(?:www\.)?youtube\.com/watch\?v=[\w-]+',
        r'https?://(?:www\.)?youtube\.com/playlist\?list=[\w-]+',
        r'https?://youtu\.be/[\w-]+',
        r'https?://(?:www\.)?youtube\.com/channel/[\w-]+',
        r'https?://(?:www\.)?youtube\.com/user/[\w-]+',
        r'https?://music\.youtube\.com/'
    ]
    
    for pattern in youtube_patterns:
        if re.match(pattern, url):
            return True
    return False

def download_music(url, download_id):
    """Download music using yt-dlp"""
    try:
        download_status[download_id] = {
            'status': 'starting',
            'progress': 0,
            'message': 'Initializing download...',
            'start_time': datetime.now().isoformat()
        }
        
        logger.info(f"Starting download: {url} (ID: {download_id})")
        
        # Build yt-dlp command
        cmd = [
            'yt-dlp',
            '--extract-audio',
            '--audio-format', 'mp3',
            '--audio-quality', 'best',
            '--embed-metadata',
            '--embed-thumbnail',
            '--restrict-filenames',
            '--no-warnings',
            '--progress-template', '{"progress": "%(progress._percent_str)s", "status": "%(progress.status)s"}',
            '-o', f'{DOWNLOAD_PATH}/%(uploader)s/%(title)s.%(ext)s',
            url
        ]
        
        download_status[download_id]['status'] = 'downloading'
        download_status[download_id]['message'] = 'Downloading...'
        
        # Execute yt-dlp
        process = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=1800  # 30 minute timeout
        )
        
        if process.returncode == 0:
            download_status[download_id]['status'] = 'completed'
            download_status[download_id]['progress'] = 100
            download_status[download_id]['message'] = 'Download completed successfully!'
            download_status[download_id]['end_time'] = datetime.now().isoformat()
            logger.info(f"Download completed: {url} (ID: {download_id})")
        else:
            download_status[download_id]['status'] = 'error'
            download_status[download_id]['message'] = f'Download failed: {process.stderr}'
            download_status[download_id]['end_time'] = datetime.now().isoformat()
            logger.error(f"Download failed: {url} (ID: {download_id}) - {process.stderr}")
    
    except subprocess.TimeoutExpired:
        download_status[download_id]['status'] = 'error'
        download_status[download_id]['message'] = 'Download timed out'
        download_status[download_id]['end_time'] = datetime.now().isoformat()
        logger.error(f"Download timed out: {url} (ID: {download_id})")
    
    except Exception as e:
        download_status[download_id]['status'] = 'error'
        download_status[download_id]['message'] = f'Error: {str(e)}'
        download_status[download_id]['end_time'] = datetime.now().isoformat()
        logger.error(f"Download error: {url} (ID: {download_id}) - {str(e)}")

@app.route('/dashboard')
def dashboard():
    """Unified dashboard page"""
    return render_template('dashboard.html')

@app.route('/')
def index():
    """Main page with download form"""
    # Pre-fill URL if provided as query parameter
    url = request.args.get('url', '')
    return render_template('index.html', prefill_url=url)

@app.route('/download', methods=['POST'])
def start_download():
    """Start a new download"""
    url = request.form.get('url', '').strip()
    
    if not url:
        flash('Please provide a YouTube URL', 'error')
        return redirect(url_for('index'))
    
    if not is_valid_youtube_url(url):
        flash('Please provide a valid YouTube URL', 'error')
        return redirect(url_for('index'))
    
    # Generate download ID
    download_id = f"dl_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{len(download_status)}"
    
    # Start download in background (in production, use Celery or similar)
    import threading
    thread = threading.Thread(target=download_music, args=(url, download_id))
    thread.daemon = True
    thread.start()
    
    flash(f'Download started! ID: {download_id}', 'success')
    return redirect(url_for('status', download_id=download_id))

@app.route('/status/<download_id>')
def status(download_id):
    """Show download status page"""
    if download_id not in download_status:
        flash('Download ID not found', 'error')
        return redirect(url_for('index'))
    
    return render_template('status.html', 
                         download_id=download_id, 
                         status=download_status[download_id])

@app.route('/api/status/<download_id>')
def api_status(download_id):
    """API endpoint for download status"""
    if download_id not in download_status:
        return jsonify({'error': 'Download ID not found'}), 404
    
    return jsonify(download_status[download_id])

@app.route('/api/downloads')
def api_downloads():
    """API endpoint to list all downloads"""
    return jsonify(download_status)

@app.route('/queue')
def queue_page():
    """Show download queue/history"""
    return render_template('queue.html', downloads=download_status)

@app.route('/api/queue', methods=['POST'])
def add_to_queue():
    """Add URL to download queue"""
    data = request.get_json()
    url = data.get('url', '').strip()
    
    if not url:
        return jsonify({'error': 'URL is required'}), 400
    
    if not is_valid_youtube_url(url):
        return jsonify({'error': 'Invalid YouTube URL'}), 400
    
    # Add to queue file for batch processing
    queue_file = '/app/queue/download_queue.txt'
    os.makedirs(os.path.dirname(queue_file), exist_ok=True)
    
    with open(queue_file, 'a') as f:
        f.write(f"{url}\n")
    
    return jsonify({'message': 'URL added to queue', 'url': url})

if __name__ == '__main__':
    # Create necessary directories
    os.makedirs(DOWNLOAD_PATH, exist_ok=True)
    os.makedirs('/app/logs', exist_ok=True)
    os.makedirs('/app/queue', exist_ok=True)
    
    # Run the app
    app.run(host='0.0.0.0', port=80, debug=False)
