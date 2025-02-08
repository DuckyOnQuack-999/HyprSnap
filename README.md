<div align="center">

# ⚡ HyprSnap

_Lightning-fast screen capture suite for modern Linux_  
_Created by [DuckyOnQuack-999](https://github.com/DuckyOnQuack-999)_

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/DuckyOnQuack-999/HyprSnap/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Issues](https://img.shields.io/github/issues/DuckyOnQuack-999/HyprSnap)](https://github.com/DuckyOnQuack-999/HyprSnap/issues)
[![Last Commit](https://img.shields.io/github/last-commit/DuckyOnQuack-999/HyprSnap)](https://github.com/DuckyOnQuack-999/HyprSnap/commits/main)

[![Wayland](https://img.shields.io/badge/Wayland-Compatible-blue.svg)](https://wayland.freedesktop.org/)
[![Hypr Ready](https://img.shields.io/badge/Hypr-Ready-purple.svg)](https://hyprland.org/)
[![System](https://img.shields.io/badge/Linux-Modern-orange.svg)](https://github.com/DuckyOnQuack-999/HyprSnap#-system-compatibility)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)

<img src="https://i.imgur.com/YourBannerImage.png" alt="HyprSnap Banner" width="600"/>

_Capture your screen in style - GIFs today, screenshots tomorrow!_

</div>

## ⚡ What is HyprSnap?

HyprSnap is your all-in-one screen capture solution for the modern Linux desktop. Built with Hyprland users in mind but compatible with all Wayland compositors, it offers:

- 🎥 **GIF Recording** - Create stunning, optimized GIFs (Available Now!)
- 📸 **Screenshots** - Quick static captures _(Coming Soon!)_

Perfect for developers, content creators, and anyone who needs professional-quality screen captures.

## 🎯 Perfect For

- 📝 Bug reports and issues
- 🎨 UI/UX showcases
- 📚 Documentation
- 🎮 Gaming moments
- 🔧 Technical demos
- 💻 Development workflows

## ✨ Current Features

### GIF Recording
- ⚡ Instant area selection
- 🎨 High-fidelity output
- 🚄 Adjustable frame rates
- 🔮 Smart optimization
- ⌨️ Global shortcuts
- 🪄 Modern notifications

### Coming Soon
- 📸 Static screenshots
- ✂️ Quick editing tools
- 📋 Clipboard integration
- ☁️ Upload shortcuts
- 🎨 Annotation tools

## 🛠️ Requirements

### Core Dependencies
- `wf-recorder`: Screen capture engine
- `ffmpeg`: Media processing
- `dunstify`: Notifications
- `slurp`: Area selection
- `wl-copy`/`xclip`: Clipboard operations

### System Requirements

#### Minimum Requirements
- Linux kernel 5.10+
- Wayland compositor
- Bash 4.0+
- 1GB storage space
- 2GB RAM

#### Recommended Setup
- Linux kernel 6.0+
- Hyprland/Sway compositor
- 4GB RAM
- SSD storage
- Modern GPU with hardware encoding

#### Tested Environments
- **Distributions**
- Arch Linux / Manjaro (Primary)
- Ubuntu 22.04+
- Fedora 38+
- openSUSE Tumbleweed

- **Compositors**
- Hyprland (Recommended)
- Sway
- GNOME Wayland
- KDE Plasma Wayland

> Note: X11 support is limited and not recommended

## ⚡ Quick Start

### Express Installation
```bash
git clone https://github.com/DuckyOnQuack-999/HyprSnap.git && cd HyprSnap && chmod +x setup.sh && ./setup.sh
```

### Manual Setup
1. Clone the repo:
```bash
git clone https://github.com/DuckyOnQuack-999/HyprSnap.git
cd HyprSnap
```

2. Run setup:
```bash
chmod +x setup.sh
./setup.sh
```

## 🎮 Usage

### GIF Recording

#### Quick Capture
```bash
./hyprsnap.sh record
```

#### Advanced Options

| Command | Purpose | Default | Pro Tips |
|---------|---------|---------|----------|
| `-q, --quality <1-100>` | Set GIF clarity | 90 | 85 for web |
| `-f, --fps <number>` | Control smoothness | 15 | 30 for animations |
| `-o, --optimize` | Reduce file size | off | Great for sharing |
| `-d, --debug` | Troubleshooting | off | Verbose output |

#### Recording Profiles

For perfect demos:
```bash
./hyprsnap.sh record -q 95 -f 30
```

For web sharing:
```bash
./hyprsnap.sh record -q 75 -f 15 --optimize
```

### Screenshots (Coming Soon!)
```bash
./hyprsnap.sh shot    # Full screenshot
./hyprsnap.sh area    # Area selection
./hyprsnap.sh window  # Active window
```

### ⚡ Workflow

#### GIF Recording
1. **Launch** 🚀 Start HyprSnap
2. **Select** 🎯 Choose area
3. **Record** 📹 Capture content
4. **Stop** ⌨️ `Super+Ctrl+C`
5. **Wait** ⚡ Processing
6. **Share** 🌟 Done!

### 📂 Output Location

Your captures are saved here:
```
~/Pictures/HyprSnap/
├── Gifs/      # GIF recordings
└── Screenshots/  # Static captures (coming soon)
```

## 🔧 Troubleshooting

### Debug Mode
Run with debug output enabled:
```bash
./hyprsnap.sh record -d
# or
./setup.sh --debug
```

### Dependency Verification
Check all dependencies are properly installed:
```bash
./setup.sh --check
```

### Common Solutions

🔴 **Recording Issues**
- Check wf-recorder installation
- Verify Wayland compositor
- Use debug mode

⚫ **Display Problems**
- Review screen permissions
- Check compositor settings

🔵 **Performance Tips**
- Lower quality for speed
- Reduce capture area
- Enable optimization

## 🤝 Contributing

Help shape HyprSnap! All contributions are welcome!

### How to Contribute

1. Fork it 🍴
2. Branch it 🌿
```bash
git checkout -b feature/amazing-idea
```
3. Code it 💻
4. Test it 🧪
```bash
# Run the test suite
./tests/run_tests.sh

# Test with debug output
./hyprsnap.sh record -d
```
5. Push it 🚀
```bash
git push origin feature/amazing-idea
```
6. PR it 🎉

### Code Style Guidelines
- Use shellcheck for bash scripts
- Follow the existing code formatting
- Comment complex logic
- Update documentation for new features

### Reporting Issues
1. Use the [issue template](https://github.com/DuckyOnQuack-999/HyprSnap/issues/new/choose)
2. Include system information:
```bash
./hyprsnap.sh --system-info
```
3. Attach debug logs:
```bash
./hyprsnap.sh record -d > debug.log 2>&1
```
4. Provide clear reproduction steps

### Feature Roadmap
- [ ] Screenshot support
- [ ] Basic image editing
- [ ] Upload integration
- [ ] Annotation tools
- [ ] Configuration file support

## 📝 Version History

### v1.0.0 (Current)
- Initial stable release
- GIF recording functionality
- Wayland compositor support
- Optimization features
- Basic notification system

### Development
- Main branch: Latest features
- Release branches: Stable versions
- See [CHANGELOG.md](CHANGELOG.md) for detailed history
- Check [releases](https://github.com/DuckyOnQuack-999/HyprSnap/releases) for latest updates

### Versioning
HyprSnap follows [Semantic Versioning](https://semver.org/):
- MAJOR.MINOR.PATCH
- Breaking.Feature.Fix

## 📄 License

HyprSnap is released under the MIT License. Copyright (c) 2023 DuckyOnQuack-999.

See [LICENSE](LICENSE) for the full license text.

By contributing to HyprSnap, you agree to license your contributions under the MIT License.

## 💝 Credits

- Hyprland community
- wf-recorder & ffmpeg teams
- All contributors

---
<div align="center">
Crafted with 💫 by <a href="https://github.com/DuckyOnQuack-999">DuckyOnQuack-999</a>

<p>If HyprSnap helps you, consider giving it a ⭐!</p>
</div>
