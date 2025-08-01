#!/usr/bin/env python3
"""
Enhanced Metadata Extractor for Music Files
Uses MusicBrainz, Spotify API, and Last.fm for comprehensive metadata
"""

import os
import sys
import json
import requests
import mutagen
from mutagen.id3 import ID3, TALB, TIT2, TPE1, TPE2, TDRC, TCON, APIC
from mutagen.mp3 import MP3
import musicbrainzngs
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import pylast
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class MetadataEnhancer:
    def __init__(self, config_path="/app/config/config.env"):
        self.config = self.load_config(config_path)
        self.setup_apis()
    
    def load_config(self, config_path):
        """Load configuration from environment file"""
        config = {}
        try:
            with open(config_path, 'r') as f:
                for line in f:
                    if '=' in line and not line.startswith('#'):
                        key, value = line.strip().split('=', 1)
                        config[key] = value.strip('"')
        except FileNotFoundError:
            logger.warning(f"Config file not found: {config_path}")
        return config
    
    def setup_apis(self):
        """Initialize API connections"""
        try:
            # MusicBrainz setup
            musicbrainzngs.set_useragent("MusicServer", "2.0", "your-email@example.com")
            
            # Spotify setup (requires API keys)
            spotify_client_id = self.config.get('SPOTIFY_CLIENT_ID')
            spotify_client_secret = self.config.get('SPOTIFY_CLIENT_SECRET')
            
            if spotify_client_id and spotify_client_secret:
                client_credentials_manager = SpotifyClientCredentials(
                    client_id=spotify_client_id,
                    client_secret=spotify_client_secret
                )
                self.spotify = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
            else:
                self.spotify = None
                logger.warning("Spotify API credentials not found")
            
            # Last.fm setup
            lastfm_api_key = self.config.get('LASTFM_API_KEY')
            if lastfm_api_key:
                self.lastfm = pylast.LastFMNetwork(api_key=lastfm_api_key)
            else:
                self.lastfm = None
                logger.warning("Last.fm API key not found")
                
        except Exception as e:
            logger.error(f"Error setting up APIs: {e}")
    
    def extract_youtube_metadata(self, filename):
        """Extract basic metadata from YouTube filename"""
        # Parse common YouTube filename patterns
        basename = os.path.splitext(os.path.basename(filename))[0]
        
        # Try to extract artist and title from various patterns
        patterns = [
            r'(.+?)\s*-\s*(.+)',  # Artist - Title
            r'(.+?)\s*–\s*(.+)',  # Artist – Title (em dash)
            r'(.+?)\s*:\s*(.+)',  # Artist : Title
        ]
        
        for pattern in patterns:
            import re
            match = re.match(pattern, basename)
            if match:
                return {
                    'artist': match.group(1).strip(),
                    'title': match.group(2).strip()
                }
        
        return {'title': basename, 'artist': 'Unknown Artist'}
    
    def enhance_with_musicbrainz(self, artist, title):
        """Get enhanced metadata from MusicBrainz"""
        try:
            # Search for recording
            result = musicbrainzngs.search_recordings(
                artist=artist, 
                recording=title, 
                limit=1
            )
            
            if result['recording-list']:
                recording = result['recording-list'][0]
                
                # Get additional details
                recording_id = recording['id']
                detailed = musicbrainzngs.get_recording_by_id(
                    recording_id, 
                    includes=['artists', 'releases', 'tags']
                )
                
                metadata = {
                    'artist': recording.get('artist-credit', [{}])[0].get('artist', {}).get('name', artist),
                    'title': recording.get('title', title),
                    'duration': recording.get('length'),
                    'tags': [tag['name'] for tag in detailed['recording'].get('tag-list', [])],
                }
                
                # Get release info if available
                if 'release-list' in detailed['recording']:
                    release = detailed['recording']['release-list'][0]
                    metadata.update({
                        'album': release.get('title'),
                        'date': release.get('date'),
                        'country': release.get('country')
                    })
                
                return metadata
                
        except Exception as e:
            logger.warning(f"MusicBrainz lookup failed: {e}")
        
        return {}
    
    def enhance_with_spotify(self, artist, title):
        """Get enhanced metadata from Spotify"""
        if not self.spotify:
            return {}
        
        try:
            # Search for track
            query = f"artist:{artist} track:{title}"
            results = self.spotify.search(q=query, type='track', limit=1)
            
            if results['tracks']['items']:
                track = results['tracks']['items'][0]
                
                # Get audio features
                audio_features = self.spotify.audio_features(track['id'])[0]
                
                metadata = {
                    'spotify_id': track['id'],
                    'popularity': track['popularity'],
                    'album': track['album']['name'],
                    'release_date': track['album']['release_date'],
                    'genres': track['artists'][0].get('genres', []),
                    'duration_ms': track['duration_ms'],
                    'explicit': track['explicit']
                }
                
                # Add audio features
                if audio_features:
                    metadata.update({
                        'danceability': audio_features['danceability'],
                        'energy': audio_features['energy'],
                        'valence': audio_features['valence'],
                        'tempo': audio_features['tempo'],
                        'key': audio_features['key'],
                        'mode': audio_features['mode'],
                        'acousticness': audio_features['acousticness'],
                        'instrumentalness': audio_features['instrumentalness'],
                        'speechiness': audio_features['speechiness']
                    })
                
                return metadata
                
        except Exception as e:
            logger.warning(f"Spotify lookup failed: {e}")
        
        return {}
    
    def enhance_with_lastfm(self, artist, title):
        """Get enhanced metadata from Last.fm"""
        if not self.lastfm:
            return {}
        
        try:
            track = self.lastfm.get_track(artist, title)
            
            metadata = {
                'lastfm_tags': [tag.item.get_name() for tag in track.get_top_tags(limit=10)],
                'lastfm_listeners': track.get_listener_count(),
                'lastfm_playcount': track.get_playcount(),
                'lastfm_url': track.get_url()
            }
            
            # Get similar tracks
            similar = track.get_similar(limit=5)
            metadata['similar_tracks'] = [
                f"{s.item.artist} - {s.item.title}" for s in similar
            ]
            
            return metadata
            
        except Exception as e:
            logger.warning(f"Last.fm lookup failed: {e}")
        
        return {}
    
    def write_enhanced_metadata(self, filepath, metadata):
        """Write enhanced metadata to music file"""
        try:
            audio_file = MP3(filepath, ID3=ID3)
            
            # Add or update ID3 tags
            if 'title' in metadata:
                audio_file.tags.add(TIT2(encoding=3, text=metadata['title']))
            
            if 'artist' in metadata:
                audio_file.tags.add(TPE1(encoding=3, text=metadata['artist']))
            
            if 'album' in metadata:
                audio_file.tags.add(TALB(encoding=3, text=metadata['album']))
            
            if 'date' in metadata or 'release_date' in metadata:
                year = metadata.get('date', metadata.get('release_date', ''))[:4]
                if year:
                    audio_file.tags.add(TDRC(encoding=3, text=year))
            
            # Add genre from tags or Spotify
            genres = []
            if 'tags' in metadata:
                genres.extend(metadata['tags'][:3])  # Top 3 MusicBrainz tags
            if 'genres' in metadata:
                genres.extend(metadata['genres'][:2])  # Top 2 Spotify genres
            if 'lastfm_tags' in metadata:
                genres.extend(metadata['lastfm_tags'][:2])  # Top 2 Last.fm tags
            
            if genres:
                audio_file.tags.add(TCON(encoding=3, text='; '.join(genres[:5])))
            
            # Save custom metadata as comments
            custom_data = {
                'enhanced_metadata': True,
                'spotify_data': {k: v for k, v in metadata.items() if k.startswith('spotify_') or k in ['popularity', 'danceability', 'energy', 'valence']},
                'lastfm_data': {k: v for k, v in metadata.items() if k.startswith('lastfm_')},
                'musicbrainz_data': {k: v for k, v in metadata.items() if k in ['tags', 'duration']}
            }
            
            # Store as JSON in a custom frame for later use by recommendation engine
            from mutagen.id3 import TXXX
            audio_file.tags.add(TXXX(encoding=3, desc='ENHANCED_METADATA', text=json.dumps(custom_data)))
            
            audio_file.save()
            logger.info(f"Enhanced metadata written to: {filepath}")
            
        except Exception as e:
            logger.error(f"Error writing metadata to {filepath}: {e}")
    
    def process_file(self, filepath):
        """Process a single music file"""
        logger.info(f"Processing: {filepath}")
        
        # Extract basic info from filename
        basic_metadata = self.extract_youtube_metadata(filepath)
        artist = basic_metadata['artist']
        title = basic_metadata['title']
        
        # Enhance with external APIs
        enhanced_metadata = basic_metadata.copy()
        
        if self.config.get('ENABLE_MUSICBRAINZ_LOOKUP', 'true').lower() == 'true':
            mb_data = self.enhance_with_musicbrainz(artist, title)
            enhanced_metadata.update(mb_data)
        
        if self.config.get('ENABLE_SPOTIFY_METADATA', 'true').lower() == 'true':
            spotify_data = self.enhance_with_spotify(artist, title)
            enhanced_metadata.update(spotify_data)
        
        if self.config.get('ENABLE_LASTFM_METADATA', 'true').lower() == 'true':
            lastfm_data = self.enhance_with_lastfm(artist, title)
            enhanced_metadata.update(lastfm_data)
        
        # Write enhanced metadata
        self.write_enhanced_metadata(filepath, enhanced_metadata)
        
        return enhanced_metadata
    
    def process_directory(self, directory):
        """Process all music files in a directory"""
        music_extensions = ['.mp3', '.m4a', '.flac', '.ogg']
        
        for root, dirs, files in os.walk(directory):
            for file in files:
                if any(file.lower().endswith(ext) for ext in music_extensions):
                    filepath = os.path.join(root, file)
                    try:
                        self.process_file(filepath)
                    except Exception as e:
                        logger.error(f"Error processing {filepath}: {e}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python enhance_metadata.py <file_or_directory>")
        sys.exit(1)
    
    path = sys.argv[1]
    enhancer = MetadataEnhancer()
    
    if os.path.isfile(path):
        enhancer.process_file(path)
    elif os.path.isdir(path):
        enhancer.process_directory(path)
    else:
        logger.error(f"Path not found: {path}")
        sys.exit(1)

if __name__ == "__main__":
    main()
