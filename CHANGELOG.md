# Changelog

All notable changes to HyprSnap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Screenshot functionality
- Basic image editing tools
- Upload integration (Imgur, custom servers)
- Annotation tools
- Configuration file support
- GUI interface
- Multi-monitor support improvements

## [1.0.0] - 2025-01-XX

### Added
- Initial stable release
- GIF recording functionality with area selection
- High-quality GIF output with customizable settings
- Smart optimization for web sharing
- Wayland compositor support (Hyprland, Sway, GNOME, KDE)
- Modern notification system using dunstify
- Comprehensive setup script with automatic dependency installation
- Support for multiple Linux distributions (Arch, Ubuntu, Fedora, openSUSE)
- Command-line interface with intuitive options
- Debug mode for troubleshooting
- System information reporting
- Automatic directory structure creation
- Desktop entry integration
- Hyprland keybinding setup
- Clipboard integration (Wayland and X11)
- Configurable quality and frame rate settings
- File size optimization options
- Comprehensive logging system
- Error handling and user feedback
- MIT license

### Technical Features
- Built with Bash for maximum compatibility
- Uses wf-recorder for efficient screen capture
- FFmpeg integration for high-quality GIF conversion
- Slurp integration for precise area selection
- Color palette optimization for better GIF quality
- Temporary file cleanup for system hygiene
- Signal handling for graceful shutdown
- Cross-platform clipboard support

### Supported Environments
- **Compositors**: Hyprland (recommended), Sway, GNOME Wayland, KDE Plasma Wayland
- **Distributions**: Arch Linux, Manjaro, Ubuntu 22.04+, Fedora 38+, openSUSE Tumbleweed
- **Requirements**: Linux kernel 5.10+, Wayland, Bash 4.0+, 2GB RAM minimum

### Dependencies
- `wf-recorder`: Screen recording engine
- `ffmpeg`: Media processing and GIF conversion
- `slurp`: Area selection tool
- `dunstify`: Modern notification system
- `wl-copy`/`xclip`: Clipboard integration

## [0.9.0] - Development

### Added
- Core GIF recording functionality
- Basic area selection
- Command-line interface prototype
- Initial Wayland support

### Changed
- Improved error handling
- Enhanced notification system

### Fixed
- Memory leaks in recording process
- Temporary file cleanup issues

## [0.1.0] - Initial Development

### Added
- Project structure
- Basic recording concept
- Dependency analysis
- Initial documentation

---

## Development Notes

### Version Numbering
- **MAJOR**: Breaking changes to CLI or core functionality
- **MINOR**: New features, significant improvements
- **PATCH**: Bug fixes, minor improvements, documentation updates

### Release Process
1. Update version numbers in scripts
2. Update CHANGELOG.md
3. Create release branch
4. Test on supported distributions
5. Create GitHub release with binaries
6. Update documentation

### Contribution Guidelines
- All changes must be documented in CHANGELOG.md
- Follow [Conventional Commits](https://www.conventionalcommits.org/) format
- Test on at least two different distributions
- Update version numbers consistently across all files

### Compatibility Promise
- CLI interface stability within major versions
- Configuration file backward compatibility
- Dependency requirements clearly documented
- Migration guides for breaking changes

---

**Legend:**
- `Added` for new features
- `Changed` for changes in existing functionality
- `Deprecated` for soon-to-be removed features
- `Removed` for now removed features
- `Fixed` for any bug fixes
- `Security` for vulnerability fixes