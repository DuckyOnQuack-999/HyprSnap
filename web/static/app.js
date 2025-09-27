/**
 * HyprSnap Web Interface JavaScript
 * Modern, responsive web UI for screen capture
 */

class HyprSnapWeb {
    constructor() {
        this.recording = false;
        this.config = {};
        this.init();
    }

    async init() {
        await this.loadConfig();
        this.setupEventListeners();
        this.setupSliders();
        this.loadFiles();
        this.startStatusUpdates();
        this.showToast('HyprSnap Web Interface loaded', 'success');
    }

    async loadConfig() {
        try {
            const response = await fetch('/api/config');
            this.config = await response.json();
            this.updateUI();
        } catch (error) {
            console.error('Failed to load config:', error);
            this.showToast('Failed to load configuration', 'error');
        }
    }

    async updateConfig(newConfig) {
        try {
            const response = await fetch('/api/config', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(newConfig)
            });
            
            if (response.ok) {
                this.config = await response.json();
                this.updateUI();
                this.showToast('Configuration updated', 'success');
            } else {
                throw new Error('Failed to update config');
            }
        } catch (error) {
            console.error('Failed to update config:', error);
            this.showToast('Failed to update configuration', 'error');
        }
    }

    setupEventListeners() {
        // Screenshot buttons
        document.getElementById('screenshot-full').addEventListener('click', () => this.takeScreenshot('full'));
        document.getElementById('screenshot-area').addEventListener('click', () => this.takeScreenshot('area'));
        document.getElementById('screenshot-window').addEventListener('click', () => this.takeScreenshot('window'));

        // Recording buttons
        document.getElementById('record-start').addEventListener('click', () => this.startRecording());
        document.getElementById('record-stop').addEventListener('click', () => this.stopRecording());

        // Settings
        document.getElementById('settings-btn').addEventListener('click', () => this.openSettings());
        document.getElementById('close-settings').addEventListener('click', () => this.closeSettings());
        document.getElementById('save-settings').addEventListener('click', () => this.saveSettings());
        document.getElementById('cancel-settings').addEventListener('click', () => this.closeSettings());

        // File refresh
        document.getElementById('refresh-files').addEventListener('click', () => this.loadFiles());

        // Format change
        document.getElementById('format-select').addEventListener('change', (e) => {
            this.updateRecordingButton(e.target.value);
        });
    }

    setupSliders() {
        // Quality slider
        const qualitySlider = document.getElementById('quality-slider');
        const qualityValue = document.getElementById('quality-value');
        qualitySlider.addEventListener('input', (e) => {
            qualityValue.textContent = e.target.value;
        });

        // FPS slider
        const fpsSlider = document.getElementById('fps-slider');
        const fpsValue = document.getElementById('fps-value');
        fpsSlider.addEventListener('input', (e) => {
            fpsValue.textContent = e.target.value;
        });

        // Default quality slider
        const defaultQualitySlider = document.getElementById('default-quality');
        const defaultQualityValue = document.getElementById('default-quality-value');
        defaultQualitySlider.addEventListener('input', (e) => {
            defaultQualityValue.textContent = e.target.value;
        });

        // Default FPS slider
        const defaultFpsSlider = document.getElementById('default-fps');
        const defaultFpsValue = document.getElementById('default-fps-value');
        defaultFpsSlider.addEventListener('input', (e) => {
            defaultFpsValue.textContent = e.target.value;
        });
    }

    updateUI() {
        // Update sliders with current config
        document.getElementById('quality-slider').value = this.config.default_quality || 80;
        document.getElementById('quality-value').textContent = this.config.default_quality || 80;
        document.getElementById('fps-slider').value = this.config.default_fps || 15;
        document.getElementById('fps-value').textContent = this.config.default_fps || 15;
        document.getElementById('default-quality').value = this.config.default_quality || 80;
        document.getElementById('default-quality-value').textContent = this.config.default_quality || 80;
        document.getElementById('default-fps').value = this.config.default_fps || 15;
        document.getElementById('default-fps-value').textContent = this.config.default_fps || 15;
        document.getElementById('save-dir').value = this.config.save_directory || '~/Pictures/HyprSnap';
    }

    async takeScreenshot(type) {
        const format = document.getElementById('format-select').value;
        const quality = document.getElementById('quality-slider').value;

        try {
            this.showToast(`Taking ${type} screenshot...`, 'info');
            
            const response = await fetch('/api/screenshot', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: type,
                    format: format,
                    quality: parseInt(quality)
                })
            });

            const result = await response.json();
            
            if (result.status === 'success') {
                this.showToast('Screenshot taken successfully!', 'success');
                this.loadFiles();
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('Screenshot error:', error);
            this.showToast(`Screenshot failed: ${error.message}`, 'error');
        }
    }

    async startRecording() {
        const format = document.getElementById('format-select').value;
        const fps = document.getElementById('fps-slider').value;
        const quality = document.getElementById('quality-slider').value;
        const audio = document.getElementById('record-audio').checked;

        try {
            this.showToast('Starting recording...', 'info');
            
            const response = await fetch('/api/record', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: 'full',
                    format: format,
                    fps: parseInt(fps),
                    quality: parseInt(quality),
                    audio: audio
                })
            });

            const result = await response.json();
            
            if (result.status === 'success') {
                this.recording = true;
                this.updateRecordingUI();
                this.showToast('Recording started!', 'success');
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('Recording error:', error);
            this.showToast(`Recording failed: ${error.message}`, 'error');
        }
    }

    async stopRecording() {
        try {
            this.showToast('Stopping recording...', 'info');
            
            const response = await fetch('/api/record/stop', {
                method: 'POST'
            });

            const result = await response.json();
            
            if (result.status === 'success') {
                this.recording = false;
                this.updateRecordingUI();
                this.showToast('Recording stopped!', 'success');
                this.loadFiles();
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('Stop recording error:', error);
            this.showToast(`Stop recording failed: ${error.message}`, 'error');
        }
    }

    updateRecordingUI() {
        const startBtn = document.getElementById('record-start');
        const stopBtn = document.getElementById('record-stop');
        const statusDot = document.getElementById('status-dot');
        const statusText = document.getElementById('status-text');

        if (this.recording) {
            startBtn.disabled = true;
            stopBtn.disabled = false;
            statusDot.className = 'w-3 h-3 bg-red-400 rounded-full pulse-animation';
            statusText.textContent = 'Recording';
        } else {
            startBtn.disabled = false;
            stopBtn.disabled = true;
            statusDot.className = 'w-3 h-3 bg-green-400 rounded-full';
            statusText.textContent = 'Ready';
        }
    }

    updateRecordingButton(format) {
        const startBtn = document.getElementById('record-start');
        if (['gif', 'mp4', 'webm'].includes(format)) {
            startBtn.disabled = false;
        } else {
            startBtn.disabled = true;
        }
    }

    async loadFiles() {
        try {
            const response = await fetch('/api/files');
            const result = await response.json();
            
            if (result.files) {
                this.displayFiles(result.files);
            }
        } catch (error) {
            console.error('Failed to load files:', error);
            this.showToast('Failed to load files', 'error');
        }
    }

    displayFiles(files) {
        const filesList = document.getElementById('files-list');
        filesList.innerHTML = '';

        if (files.length === 0) {
            filesList.innerHTML = '<p class="text-white text-center py-4">No files found</p>';
            return;
        }

        files.forEach(file => {
            const fileElement = this.createFileElement(file);
            filesList.appendChild(fileElement);
        });
    }

    createFileElement(file) {
        const div = document.createElement('div');
        div.className = 'flex items-center justify-between p-3 bg-white bg-opacity-10 rounded-lg';
        
        const icon = this.getFileIcon(file.name);
        const size = this.formatFileSize(file.size);
        const modified = new Date(file.modified).toLocaleString();

        div.innerHTML = `
            <div class="flex items-center space-x-3">
                <i class="${icon} text-2xl text-white"></i>
                <div>
                    <div class="text-white font-medium">${file.name}</div>
                    <div class="text-gray-300 text-sm">${size} • ${modified}</div>
                </div>
            </div>
            <div class="flex space-x-2">
                <button onclick="hyprSnap.downloadFile('${file.name}')" class="text-white hover:text-gray-200">
                    <i class="fas fa-download"></i>
                </button>
                <button onclick="hyprSnap.deleteFile('${file.name}')" class="text-red-400 hover:text-red-300">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;

        return div;
    }

    getFileIcon(filename) {
        const ext = filename.split('.').pop().toLowerCase();
        const iconMap = {
            'png': 'fas fa-image',
            'jpg': 'fas fa-image',
            'jpeg': 'fas fa-image',
            'webp': 'fas fa-image',
            'gif': 'fas fa-file-video',
            'mp4': 'fas fa-file-video',
            'webm': 'fas fa-file-video'
        };
        return iconMap[ext] || 'fas fa-file';
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    async downloadFile(filename) {
        try {
            const response = await fetch(`/api/files/${filename}`);
            if (response.ok) {
                const blob = await response.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = filename;
                document.body.appendChild(a);
                a.click();
                window.URL.revokeObjectURL(url);
                document.body.removeChild(a);
                this.showToast('File downloaded', 'success');
            } else {
                throw new Error('Download failed');
            }
        } catch (error) {
            console.error('Download error:', error);
            this.showToast('Download failed', 'error');
        }
    }

    async deleteFile(filename) {
        if (!confirm(`Are you sure you want to delete ${filename}?`)) {
            return;
        }

        try {
            // Note: This would need a delete endpoint in the backend
            this.showToast('Delete functionality not implemented yet', 'warning');
        } catch (error) {
            console.error('Delete error:', error);
            this.showToast('Delete failed', 'error');
        }
    }

    openSettings() {
        document.getElementById('settings-modal').classList.remove('hidden');
    }

    closeSettings() {
        document.getElementById('settings-modal').classList.add('hidden');
    }

    async saveSettings() {
        const newConfig = {
            save_directory: document.getElementById('save-dir').value,
            default_quality: parseInt(document.getElementById('default-quality').value),
            default_fps: parseInt(document.getElementById('default-fps').value)
        };

        await this.updateConfig(newConfig);
        this.closeSettings();
    }

    async startStatusUpdates() {
        setInterval(async () => {
            try {
                const response = await fetch('/api/status');
                const status = await response.json();
                
                if (status.recording_active !== this.recording) {
                    this.recording = status.recording_active;
                    this.updateRecordingUI();
                }
            } catch (error) {
                console.error('Status update error:', error);
            }
        }, 2000);
    }

    showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        
        const colors = {
            success: 'bg-green-500',
            error: 'bg-red-500',
            warning: 'bg-yellow-500',
            info: 'bg-blue-500'
        };

        toast.className = `${colors[type]} text-white px-4 py-2 rounded-lg shadow-lg transform transition-all duration-300 translate-x-full`;
        toast.textContent = message;

        container.appendChild(toast);

        // Animate in
        setTimeout(() => {
            toast.classList.remove('translate-x-full');
        }, 100);

        // Auto remove
        setTimeout(() => {
            toast.classList.add('translate-x-full');
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }, 3000);
    }
}

// Initialize the application
const hyprSnap = new HyprSnapWeb();