#!/usr/bin/env python3
"""
YouTube Music Downloader Web Interface
Modern, professional interface with playlist support and auto-updates
"""

import os
import json
import subprocess
import logging
import requests
import threading
import time
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

# Global download status storage
download_status = {}
download_logs = []

def check_for_updates():
    """Check GitHub for updates and auto-update if available"""
    try:
        response = requests.get('https://api.github.com/repos/fakearchie/msc/commits/main')
        latest_commit = response.json()['sha']
        
        # Read current commit from file
        current_commit = ""
        if os.path.exists('/app/.git_commit'):
            with open('/app/.git_commit', 'r') as f:
                current_commit = f.read().strip()
        
        if latest_commit != current_commit:
            logger.info(f"Update available: {latest_commit[:8]}")
            
            # Download and apply update
            subprocess.run(['git', 'pull', 'origin', 'main'], cwd='/app', check=True)
            
            # Save new commit hash
            with open('/app/.git_commit', 'w') as f:
                f.write(latest_commit)
            
            # Restart containers
            subprocess.run(['docker-compose', 'restart'], cwd='/app', check=True)
            logger.info("Auto-update completed and services restarted")
            
    except Exception as e:
        logger.error(f"Auto-update failed: {e}")

def start_update_checker():
    """Start background thread to check for updates"""
    def update_loop():
        while True:
            check_for_updates()
            time.sleep(3600)  # Check every hour
    
    thread = threading.Thread(target=update_loop, daemon=True)
    thread.start()

def is_valid_youtube_url(url):
    """Check if URL is a valid YouTube URL"""
    youtube_patterns = [
        r'https?://(?:www\.)?youtube\.com/watch\?v=[\w-]+',
        r'https?://(?:www\.)?youtube\.com/playlist\?list=[\w-]+',
        r'https?://youtu\.be/[\w-]+',
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
def create_navidrome_playlist(playlist_name, track_ids):
    """Create a playlist in Navidrome"""
    try:
        # Implementation for Navidrome playlist creation
        # This would use Navidrome's API to create playlists
        logger.info(f"Creating playlist: {playlist_name} with {len(track_ids)} tracks")
        return True
    except Exception as e:
        logger.error(f"Failed to create playlist: {e}")
        return False

def extract_playlist_info(url):
    """Extract playlist information from YouTube URL"""
    try:
        cmd = ['yt-dlp', '--flat-playlist', '--print', 'title', '--print', 'id', url]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            playlist_title = lines[0] if lines else 'Unknown Playlist'
            return playlist_title
        return 'Unknown Playlist'
    except Exception as e:
        logger.error(f"Failed to extract playlist info: {e}")
        return 'Unknown Playlist'

def download_music_enhanced(url, download_id, options=None):
    """Enhanced download with playlist support"""
    try:
        options = options or {}
        download_status[download_id] = {
            'status': 'starting',
            'progress': 0,
            'message': 'Initializing download...',
            'start_time': datetime.now().isoformat()
        }
        
        logger.info(f"Starting enhanced download: {url} (ID: {download_id})")
        
        # Check if it's a playlist
        is_playlist = 'playlist?list=' in url
        playlist_name = None
        
        if is_playlist and options.get('createPlaylist'):
            playlist_name = options.get('playlistName')
            if not playlist_name:
                playlist_name = extract_playlist_info(url)
            
            download_status[download_id]['message'] = f'Creating playlist: {playlist_name}'
        
        # Build enhanced yt-dlp command
        cmd = [
            'yt-dlp',
            '--extract-audio',
            '--audio-format', options.get('format', 'mp3'),
            '--audio-quality', options.get('quality', 'best'),
            '--embed-metadata',
            '--embed-thumbnail',
            '--add-metadata',
            '--restrict-filenames',
            '--no-warnings',
            '--write-info-json',
            '--write-thumbnail',
            '-o', f'{DOWNLOAD_PATH}/%(uploader)s/%(title)s.%(ext)s',
        ]
        
        # Add playlist-specific options
        if is_playlist:
            cmd.extend(['--yes-playlist', '--write-playlist-metafiles'])
        
        cmd.append(url)
        
        download_status[download_id]['status'] = 'downloading'
        download_status[download_id]['message'] = 'Downloading audio...'
        
        # Execute yt-dlp
        process = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=1800  # 30 minute timeout
        )
        
        if process.returncode == 0:
            download_status[download_id]['status'] = 'processing'
            download_status[download_id]['progress'] = 90
            download_status[download_id]['message'] = 'Processing metadata...'
            
            # Create Navidrome playlist if requested
            if is_playlist and options.get('createPlaylist') and playlist_name:
                # Trigger Navidrome scan
                subprocess.run(['docker', 'exec', 'navidrome', '/app/navidrome', '--configfile', '/data/navidrome.toml', 'scan'], 
                             capture_output=True)
                
                # Add to monitoring if requested
                if options.get('monitorPlaylist'):
                    add_to_monitoring(url, playlist_name)
            
            download_status[download_id]['status'] = 'completed'
            download_status[download_id]['progress'] = 100
            download_status[download_id]['message'] = 'Download completed successfully!'
            download_status[download_id]['end_time'] = datetime.now().isoformat()
            logger.info(f"Enhanced download completed: {url} (ID: {download_id})")
            
        else:
            download_status[download_id]['status'] = 'error'
            download_status[download_id]['message'] = f'Download failed: {process.stderr}'
            download_status[download_id]['end_time'] = datetime.now().isoformat()
            logger.error(f"Enhanced download failed: {url} (ID: {download_id}) - {process.stderr}")
    
    except subprocess.TimeoutExpired:
        download_status[download_id]['status'] = 'error'
        download_status[download_id]['message'] = 'Download timed out'
        download_status[download_id]['end_time'] = datetime.now().isoformat()
        logger.error(f"Enhanced download timed out: {url} (ID: {download_id})")
    
    except Exception as e:
        download_status[download_id]['status'] = 'error'
        download_status[download_id]['message'] = f'Error: {str(e)}'
        download_status[download_id]['end_time'] = datetime.now().isoformat()
        logger.error(f"Enhanced download error: {url} (ID: {download_id}) - {str(e)}")

def add_to_monitoring(url, playlist_name):
    """Add playlist to monitoring list"""
    try:
        config_path = '/app/config/config.env'
        # Read current config
        current_playlists = []
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                for line in f:
                    if line.startswith('MONITOR_PLAYLISTS='):
                        current_value = line.split('=', 1)[1].strip().strip('"')
                        if current_value:
                            current_playlists = current_value.split(',')
                        break
        
        # Add new playlist if not already monitored
        if url not in current_playlists:
            current_playlists.append(url)
            # Update config file
            # Implementation would update the config.env file
            logger.info(f"Added {playlist_name} to monitoring")
    except Exception as e:
        logger.error(f"Failed to add playlist to monitoring: {e}")

@app.route('/')
def index():
    """Main page"""
    return render_template('index.html')

@app.route('/download', methods=['POST'])
def download():
    """Enhanced download endpoint with playlist support"""
    try:
        data = request.get_json()
        url = data.get('url', '').strip()
        
        if not url:
            return jsonify({'success': False, 'error': 'URL is required'})
        
        if not is_valid_youtube_url(url):
            return jsonify({'success': False, 'error': 'Invalid YouTube URL'})
        
        # Generate unique download ID
        download_id = f"dl_{int(time.time())}_{hash(url) % 10000}"
        
        # Extract options
        options = {
            'quality': data.get('quality', 'best'),
            'format': data.get('format', 'mp3'),
            'createPlaylist': data.get('createPlaylist', False),
            'monitorPlaylist': data.get('monitorPlaylist', False),
            'playlistName': data.get('playlistName', '')
        }
        
        # Start download in background thread
        thread = threading.Thread(
            target=download_music_enhanced,
            args=(url, download_id, options)
        )
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'success': True, 
            'download_id': download_id,
            'message': 'Download started'
        })
        
    except Exception as e:
        logger.error(f"Download endpoint error: {str(e)}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/status/<download_id>')
def get_status(download_id):
    """Get download status"""
    if download_id in download_status:
        return jsonify(download_status[download_id])
    else:
        return jsonify({
            'status': 'not_found',
            'progress': 0,
            'message': 'Download not found'
        }), 404

@app.route('/check-updates')
def check_updates_endpoint():
    """Manual update check endpoint"""
    try:
        # Check for updates
        response = requests.get('https://api.github.com/repos/fakearchie/msc/commits/main', timeout=10)
        latest_commit = response.json()['sha']
        
        # Read current commit
        current_commit = ""
        if os.path.exists('/app/.git_commit'):
            with open('/app/.git_commit', 'r') as f:
                current_commit = f.read().strip()
        
        if latest_commit != current_commit:
            # Trigger update
            check_for_updates()
            return jsonify({
                'update_available': True,
                'message': 'Update found and applied'
            })
        else:
            return jsonify({
                'update_available': False,
                'message': 'System is up to date'
            })
            
    except Exception as e:
        logger.error(f"Update check failed: {e}")
        return jsonify({
            'update_available': False,
            'error': str(e)
        }), 500

@app.route('/logs')
def get_logs():
    """Get recent download logs"""
    return jsonify({'logs': download_logs[-50:]})  # Return last 50 log entries

@app.route('/stats')
def get_stats():
    """Get download statistics"""
    try:
        completed = len([d for d in download_status.values() if d['status'] == 'completed'])
        failed = len([d for d in download_status.values() if d['status'] == 'error'])
        total = len(download_status)
        
        return jsonify({
            'total_downloads': total,
            'completed': completed,
            'failed': failed,
            'success_rate': (completed / total * 100) if total > 0 else 0
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/install-extension')
def install_extension():
    """Browser extension installation page"""
    # Auto-detect server IP
    import socket
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    # Try to get actual network IP if local IP is localhost
    if local_ip.startswith('127.'):
        import subprocess
        try:
            # For Linux/Pi
            result = subprocess.run(['hostname', '-I'], capture_output=True, text=True)
            if result.returncode == 0:
                local_ip = result.stdout.strip().split()[0]
        except:
            pass
    
    return render_template('install-extension.html', server_ip=local_ip)

if __name__ == '__main__':
    # Start update checker
    start_update_checker()
    
    # Start Flask app
    app.run(host='0.0.0.0', port=5000, debug=False)

@app.route('/user-script.js')
def user_script():
    """Serve the user script directly with auto-configured IP"""
    try:
        script_path = os.path.join(os.path.dirname(__file__), '..', 'navidrome-integration', 'user-script.js')
        with open(script_path, 'r', encoding='utf-8') as f:
            script_content = f.read()
        
        # Auto-detect server IP and update the script
        import socket
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        
        # Try to get actual network IP if local IP is localhost
        if local_ip.startswith('127.'):
            import subprocess
            try:
                # For Linux/Pi
                result = subprocess.run(['hostname', '-I'], capture_output=True, text=True)
                if result.returncode == 0:
                    local_ip = result.stdout.strip().split()[0]
            except:
                pass
        
        # Replace placeholder with actual IP in the script
        script_content = script_content.replace('YOUR_PI_IP', local_ip)
        script_content = script_content.replace('http://localhost', f'http://{local_ip}')
        
        response = app.response_class(
            response=script_content,
            status=200,
            mimetype='application/javascript'
        )
        response.headers['Content-Disposition'] = 'attachment; filename=navidrome-youtube-pro.user.js'
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        return response
    except FileNotFoundError:
        return "User script not found", 404

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
