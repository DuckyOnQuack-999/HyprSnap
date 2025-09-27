# ⚡ HyprSnap - Modern Linux Screen Capture Suite

**A fully integrated screen capture solution with both CLI and Web UI**

## 🎯 Project Overview

HyprSnap is a comprehensive screen capture suite designed for modern Linux desktops, especially Wayland compositors like Hyprland. It provides both command-line and web-based interfaces for taking screenshots and recording screen content.

## ✨ Features

### Core Functionality
- 📸 **Screenshots**: Full screen, area selection, active window
- 🎥 **Screen Recording**: GIF, MP4, WebM formats
- 🎨 **Image Processing**: Optimization, filters, batch processing
- ⚡ **Hardware Acceleration**: VAAPI, NVENC support
- 🔧 **Wayland Native**: Built for modern Linux desktops

### Interfaces
- 🖥️ **CLI Interface**: Full-featured command-line tool
- 🌐 **Web Interface**: Modern, responsive web UI
- 📱 **Mobile Friendly**: Responsive design for all devices

### Advanced Features
- 🔄 **Real-time Processing**: Live status updates
- 📁 **File Management**: Organized storage and retrieval
- ⚙️ **Configuration**: Flexible settings management
- 🚀 **Performance**: Multi-threaded processing
- 🛡️ **Security**: Path validation and safe operations

## 🏗️ Architecture

```
HyprSnap/
├── hyprsnap.sh              # Main CLI interface
├── src/core/                # Python processing modules
│   ├── processor.py         # Content analysis and processing
│   └── formatter.py         # Output formatting
├── web/                     # Web interface
│   ├── app.py              # Flask web server
│   ├── templates/          # HTML templates
│   └── static/             # CSS/JS assets
├── utils/                   # Utility modules
│   ├── config.sh           # Configuration management
│   └── error.sh            # Error handling
├── core/                    # Core functionality
│   ├── screenshot.sh       # Screenshot capture
│   └── recording.sh        # Screen recording
└── requirements.txt        # Python dependencies
```

## 🚀 Quick Start

### 1. Install Dependencies
```bash
# Install system and Python dependencies
./install-deps.sh
```

### 2. Use CLI Interface
```bash
# Take a screenshot
./hyprsnap.sh shot area

# Record screen
./hyprsnap.sh record --format mp4 --fps 30

# Start web interface
./hyprsnap.sh web --host 0.0.0.0 --port 5000
```

### 3. Access Web Interface
Open your browser and navigate to `http://localhost:5000`

## 📋 System Requirements

### Minimum Requirements
- Linux kernel 5.10+
- Wayland compositor (Hyprland, Sway, GNOME, KDE)
- Bash 4.0+
- Python 3.8+
- 2GB RAM
- 1GB storage

### Recommended Setup
- Linux kernel 6.0+
- Hyprland compositor
- 4GB RAM
- SSD storage
- Modern GPU with hardware encoding

### Dependencies
- **Core Tools**: `grim`, `slurp`, `wf-recorder`, `ffmpeg`
- **Image Processing**: `imagemagick`, `optipng`, `jpegoptim`, `libwebp`
- **Python Packages**: `flask`, `flask-cors`, `pyyaml`, `pillow`

## 🎮 Usage Examples

### CLI Usage
```bash
# Screenshots
hyprsnap shot --format png --quality 90 area
hyprsnap shot --format webp --quality 80 window

# Recording
hyprsnap record --format gif --fps 15 --quality 80
hyprsnap record --format mp4 --fps 30 --audio --hw

# Web Interface
hyprsnap web --host 0.0.0.0 --port 8080
```

### Web Interface
1. **Screenshot**: Click screenshot buttons for different capture types
2. **Recording**: Start/stop recording with audio options
3. **Settings**: Adjust quality, FPS, and output formats
4. **Files**: View, download, and manage captured files

## ⚙️ Configuration

### CLI Configuration
```bash
# Initialize configuration
hyprsnap init

# Update settings
hyprsnap config --quality 90 --fps 30
```

### Web Configuration
Access settings through the web interface or edit `~/.config/hyprsnap/config.yaml`

### Configuration Options
- `default_fps`: Default frame rate (1-60)
- `default_quality`: Default quality (1-100)
- `save_directory`: Screenshot storage location
- `gif_directory`: GIF recording storage
- `video_directory`: Video recording storage
- `optimize_by_default`: Enable automatic optimization

## 🔧 Development

### Project Structure
- **Backend**: Bash scripts for core functionality
- **Processing**: Python modules for advanced features
- **Frontend**: Modern web interface with JavaScript
- **Integration**: Seamless CLI and web coordination

### Key Components
1. **CLI Interface** (`hyprsnap.sh`): Main entry point
2. **Web Server** (`web/app.py`): Flask-based web interface
3. **Processing Engine** (`src/core/`): Python analysis and formatting
4. **Configuration** (`utils/config.sh`): Settings management
5. **Error Handling** (`utils/error.sh`): Robust error management

### Testing
```bash
# Run integration tests
./test-integration.sh

# Test specific components
./hyprsnap.sh --help
./hyprsnap.sh --version
./hyprsnap.sh web --help
```

## 🐛 Troubleshooting

### Common Issues
1. **Missing Dependencies**: Run `./install-deps.sh`
2. **Wayland Issues**: Ensure Wayland session is active
3. **Permission Errors**: Check file permissions and paths
4. **Web Interface**: Verify Flask installation

### Debug Mode
```bash
# Enable debug output
hyprsnap --debug shot area
hyprsnap web --debug
```

### Logs
- CLI logs: `~/.cache/hyprsnap/hyprsnap.log`
- Web logs: Console output when running with `--debug`

## 🤝 Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `./install-deps.sh`
3. Test functionality: `./test-integration.sh`
4. Make changes and test
5. Submit pull request

### Code Style
- Bash: Follow shellcheck guidelines
- Python: Follow PEP 8
- JavaScript: Use modern ES6+ features
- HTML/CSS: Use semantic markup and modern CSS

## 📄 License

HyprSnap is released under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Credits

- **Original Author**: DuckyOnQuack-999
- **Contributors**: All community contributors
- **Dependencies**: wf-recorder, ffmpeg, grim, slurp teams
- **Compositors**: Hyprland, Sway, GNOME, KDE communities

## 🔮 Roadmap

### Planned Features
- [ ] Cloud upload integration
- [ ] Advanced editing tools
- [ ] Mobile app companion
- [ ] Plugin system
- [ ] API documentation
- [ ] Docker support

### Recent Updates
- ✅ Modern web interface
- ✅ Integrated CLI and web
- ✅ Enhanced error handling
- ✅ Configuration management
- ✅ Hardware acceleration
- ✅ Cross-compositor support

---

**HyprSnap** - *Capture your screen in style* 🎨

For support, issues, or contributions, visit the [GitHub repository](https://github.com/DuckyOnQuack-999/HyprSnap).