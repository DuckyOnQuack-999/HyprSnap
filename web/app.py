#!/usr/bin/env python3

"""
HyprSnap Web Interface
A modern web UI for the HyprSnap screen capture suite
"""

import os
import sys
import json
import logging
import subprocess
import threading
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

try:
    from flask import Flask, render_template, request, jsonify, send_file, send_from_directory
    from flask_cors import CORS
    import websocket
    FLASK_AVAILABLE = True
except ImportError:
    FLASK_AVAILABLE = False

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('HyprSnapWeb')

class HyprSnapWeb:
    def __init__(self, host='127.0.0.1', port=5000, debug=False):
        self.host = host
        self.port = port
        self.debug = debug
        self.app = None
        self.setup_flask()
        
        # Configuration
        self.config = {
            'save_directory': os.path.expanduser('~/Pictures/HyprSnap'),
            'gif_directory': os.path.expanduser('~/Pictures/HyprSnap/GIFs'),
            'video_directory': os.path.expanduser('~/Pictures/HyprSnap/Videos'),
            'default_fps': 15,
            'default_quality': 80,
            'screenshot_format': 'png',
            'recording_format': 'gif'
        }
        
        # Ensure directories exist
        for dir_path in [self.config['save_directory'], self.config['gif_directory'], self.config['video_directory']]:
            os.makedirs(dir_path, exist_ok=True)
    
    def setup_flask(self):
        """Setup Flask application"""
        if not FLASK_AVAILABLE:
            logger.error("Flask not available. Please install: pip install flask flask-cors")
            return
        
        self.app = Flask(__name__, 
                        template_folder='templates',
                        static_folder='static')
        CORS(self.app)
        
        # Routes
        self.app.route('/')(self.index)
        self.app.route('/api/config')(self.get_config)
        self.app.route('/api/config', methods=['POST'])(self.update_config)
        self.app.route('/api/screenshot', methods=['POST'])(self.take_screenshot)
        self.app.route('/api/record', methods=['POST'])(self.start_recording)
        self.app.route('/api/record/stop', methods=['POST'])(self.stop_recording)
        self.app.route('/api/files')(self.list_files)
        self.app.route('/api/files/<path:filename>')(self.download_file)
        self.app.route('/api/status')(self.get_status)
        self.app.route('/api/logs')(self.get_logs)
        
        # Error handlers
        self.app.errorhandler(404)(self.not_found)
        self.app.errorhandler(500)(self.internal_error)
    
    def index(self):
        """Main page"""
        return render_template('index.html')
    
    def get_config(self):
        """Get current configuration"""
        return jsonify(self.config)
    
    def update_config(self):
        """Update configuration"""
        try:
            data = request.get_json()
            if data:
                self.config.update(data)
                return jsonify({'status': 'success', 'config': self.config})
            return jsonify({'status': 'error', 'message': 'No data provided'}), 400
        except Exception as e:
            logger.error(f"Error updating config: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def take_screenshot(self):
        """Take a screenshot"""
        try:
            data = request.get_json() or {}
            screenshot_type = data.get('type', 'full')  # full, area, window
            format_type = data.get('format', self.config['screenshot_format'])
            quality = data.get('quality', self.config['default_quality'])
            
            # Generate filename
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"screenshot_{timestamp}.{format_type}"
            output_path = os.path.join(self.config['save_directory'], filename)
            
            # Build command
            cmd = ['./hyprsnap.sh', 'shot', '--format', format_type, '--quality', str(quality), '-o', output_path, screenshot_type]
            
            # Execute command
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.path.dirname(os.path.abspath(__file__)) + '/..')
            
            if result.returncode == 0:
                return jsonify({
                    'status': 'success',
                    'message': 'Screenshot taken successfully',
                    'filename': filename,
                    'path': output_path
                })
            else:
                return jsonify({
                    'status': 'error',
                    'message': f'Failed to take screenshot: {result.stderr}'
                }), 500
                
        except Exception as e:
            logger.error(f"Error taking screenshot: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def start_recording(self):
        """Start screen recording"""
        try:
            data = request.get_json() or {}
            recording_type = data.get('type', 'full')  # full, area, window
            format_type = data.get('format', self.config['recording_format'])
            fps = data.get('fps', self.config['default_fps'])
            quality = data.get('quality', self.config['default_quality'])
            duration = data.get('duration', 0)  # 0 = infinite
            audio = data.get('audio', False)
            hw_accel = data.get('hw_accel', False)
            
            # Generate filename
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            if format_type == 'gif':
                filename = f"recording_{timestamp}.gif"
                output_path = os.path.join(self.config['gif_directory'], filename)
            else:
                filename = f"recording_{timestamp}.{format_type}"
                output_path = os.path.join(self.config['video_directory'], filename)
            
            # Build command
            cmd = ['./hyprsnap.sh', 'record', '--format', format_type, '--fps', str(fps), '--quality', str(quality), '-o', output_path]
            
            if duration > 0:
                cmd.extend(['--duration', str(duration)])
            if audio:
                cmd.append('--audio')
            if hw_accel:
                cmd.append('--hw')
            
            cmd.append(recording_type)
            
            # Start recording in background
            process = subprocess.Popen(cmd, cwd=os.path.dirname(os.path.abspath(__file__)) + '/..')
            
            return jsonify({
                'status': 'success',
                'message': 'Recording started',
                'filename': filename,
                'path': output_path,
                'pid': process.pid
            })
            
        except Exception as e:
            logger.error(f"Error starting recording: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def stop_recording(self):
        """Stop screen recording"""
        try:
            # Find and kill wf-recorder process
            subprocess.run(['pkill', '-f', 'wf-recorder'], capture_output=True)
            subprocess.run(['pkill', '-f', 'ffmpeg'], capture_output=True)
            
            return jsonify({
                'status': 'success',
                'message': 'Recording stopped'
            })
            
        except Exception as e:
            logger.error(f"Error stopping recording: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def list_files(self):
        """List captured files"""
        try:
            files = []
            
            # Scan all directories
            for dir_name, dir_path in [
                ('screenshots', self.config['save_directory']),
                ('gifs', self.config['gif_directory']),
                ('videos', self.config['video_directory'])
            ]:
                if os.path.exists(dir_path):
                    for filename in os.listdir(dir_path):
                        file_path = os.path.join(dir_path, filename)
                        if os.path.isfile(file_path):
                            stat = os.stat(file_path)
                            files.append({
                                'name': filename,
                                'type': dir_name,
                                'size': stat.st_size,
                                'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                                'path': file_path
                            })
            
            # Sort by modification time (newest first)
            files.sort(key=lambda x: x['modified'], reverse=True)
            
            return jsonify({'files': files})
            
        except Exception as e:
            logger.error(f"Error listing files: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def download_file(self, filename):
        """Download a file"""
        try:
            # Find file in any directory
            for dir_path in [self.config['save_directory'], self.config['gif_directory'], self.config['video_directory']]:
                file_path = os.path.join(dir_path, filename)
                if os.path.exists(file_path):
                    return send_file(file_path, as_attachment=True)
            
            return jsonify({'status': 'error', 'message': 'File not found'}), 404
            
        except Exception as e:
            logger.error(f"Error downloading file: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def get_status(self):
        """Get system status"""
        try:
            # Check if recording is active
            recording_active = False
            try:
                result = subprocess.run(['pgrep', '-f', 'wf-recorder'], capture_output=True)
                recording_active = result.returncode == 0
            except:
                pass
            
            # Get system info
            status = {
                'recording_active': recording_active,
                'wayland_session': os.environ.get('XDG_SESSION_TYPE') == 'wayland',
                'compositor': self.detect_compositor(),
                'timestamp': datetime.now().isoformat()
            }
            
            return jsonify(status)
            
        except Exception as e:
            logger.error(f"Error getting status: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def detect_compositor(self):
        """Detect current compositor"""
        if subprocess.run(['which', 'hyprctl'], capture_output=True).returncode == 0:
            return 'hyprland'
        elif subprocess.run(['which', 'swaymsg'], capture_output=True).returncode == 0:
            return 'sway'
        elif os.environ.get('XDG_CURRENT_DESKTOP'):
            return os.environ.get('XDG_CURRENT_DESKTOP').lower()
        else:
            return 'unknown'
    
    def get_logs(self):
        """Get recent logs"""
        try:
            log_file = os.path.expanduser('~/.cache/hyprsnap/hyprsnap.log')
            if os.path.exists(log_file):
                with open(log_file, 'r') as f:
                    lines = f.readlines()
                    # Return last 100 lines
                    return jsonify({'logs': lines[-100:]})
            else:
                return jsonify({'logs': []})
                
        except Exception as e:
            logger.error(f"Error getting logs: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500
    
    def not_found(self, error):
        """404 error handler"""
        return jsonify({'status': 'error', 'message': 'Not found'}), 404
    
    def internal_error(self, error):
        """500 error handler"""
        logger.error(f"Internal error: {error}")
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500
    
    def run(self):
        """Run the web server"""
        if not self.app:
            logger.error("Flask app not initialized")
            return
        
        logger.info(f"Starting HyprSnap web interface on http://{self.host}:{self.port}")
        self.app.run(host=self.host, port=self.port, debug=self.debug)

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='HyprSnap Web Interface')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    
    args = parser.parse_args()
    
    if not FLASK_AVAILABLE:
        print("Error: Flask not available. Please install dependencies:")
        print("pip install flask flask-cors")
        sys.exit(1)
    
    app = HyprSnapWeb(host=args.host, port=args.port, debug=args.debug)
    app.run()

if __name__ == '__main__':
    main()