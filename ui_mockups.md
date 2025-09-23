# HyprSnap UI Mockups and Interface Designs

## Terminal User Interface (TUI) Mockups

### 1. Main Menu Interface (Future GUI)
```
╔══════════════════════════════════════════════════════════════╗
║                        HyprSnap v1.0                        ║
║              Lightning-fast screen capture suite            ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  🎥 Record GIF                                    [Ctrl+G]   ║
║  📸 Take Screenshot                               [Ctrl+S]   ║
║  📋 View Captures                                 [Ctrl+V]   ║
║  ⚙️  Settings                                     [Ctrl+,]   ║
║  ❓ Help                                          [F1]       ║
║  🚪 Exit                                          [Ctrl+Q]   ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║ Status: Ready | Last capture: 2 minutes ago                 ║
╚══════════════════════════════════════════════════════════════╝
```

### 2. GIF Recording Settings Dialog
```
╔══════════════════════════════════════════════════════════════╗
║                    GIF Recording Settings                   ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Quality: [████████▒▒] 85%          [Slider]                ║
║                                                              ║
║  Frame Rate: [15] fps               [Input Field]           ║
║                                                              ║
║  ☐ Optimize for web sharing                                 ║
║  ☑ Copy to clipboard                                        ║
║  ☑ Show notifications                                       ║
║                                                              ║
║  Output Directory:                                           ║
║  ~/Pictures/HyprSnap/Gifs/          [Browse...]             ║
║                                                              ║
║                                                              ║
║  [Cancel]                           [Start Recording]       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### 3. Area Selection Interface
```
╔══════════════════════════════════════════════════════════════╗
║                    Select Recording Area                    ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Instructions:                                               ║
║  • Click and drag to select area                            ║
║  • Press ENTER to confirm                                   ║
║  • Press ESC to cancel                                      ║
║                                                              ║
║  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ║
║  │                                                         │  ║
║  │     Selected Area: 1920x1080                            │  ║
║  │     Position: (0, 0)                                    │  ║
║  │                                                         │  ║
║  └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ║
║                                                              ║
║  Quick Presets:                                              ║
║  [Full Screen] [Window] [Custom]                             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### 4. Recording Progress Interface
```
╔══════════════════════════════════════════════════════════════╗
║                      Recording in Progress                  ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  🔴 RECORDING                                                ║
║                                                              ║
║  Duration: 00:01:23                                          ║
║  File Size: ~2.3 MB                                          ║
║  Frame Rate: 15 fps                                          ║
║  Quality: 85%                                                ║
║                                                              ║
║  Area: 1920x1080 at (0,0)                                   ║
║                                                              ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │ ████████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ │  ║
║  │ Memory Usage: 65%                                       │  ║
║  └─────────────────────────────────────────────────────────┘  ║
║                                                              ║
║  Press Super+Ctrl+C to stop recording                       ║
║                                                              ║
║  [Stop Recording] [Pause] [Settings]                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### 5. Processing Dialog
```
╔══════════════════════════════════════════════════════════════╗
║                    Processing GIF...                        ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ⚡ Converting video to GIF                                  ║
║                                                              ║
║  Progress: [████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒] 60%                 ║
║                                                              ║
║  Current Step: Generating color palette...                  ║
║  Estimated Time: 15 seconds remaining                       ║
║                                                              ║
║  Input: temp_recording.mp4 (15.2 MB)                        ║
║  Output: hyprsnap_20250923_143052.gif                       ║
║                                                              ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │ 🎨 Optimizing colors...                                 │  ║
║  │ 🔧 Applying compression...                              │  ║
║  │ ✨ Finalizing GIF...                                   │  ║
║  └─────────────────────────────────────────────────────────┘  ║
║                                                              ║
║  [Cancel]                                                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

## Web Interface Mockup (Future Development)

### React Component Structure
```tsx
// Main HyprSnap Web Interface
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Slider } from "@/components/ui/slider"
import { Switch } from "@/components/ui/switch"
import { Progress } from "@/components/ui/progress"
import { Camera, Video, Settings, FolderOpen, Download } from "lucide-react"

export default function HyprSnapInterface() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 p-6">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">
            ⚡ HyprSnap
          </h1>
          <p className="text-purple-200">
            Lightning-fast screen capture suite for modern Linux
          </p>
        </div>

        {/* Main Controls */}
        <div className="grid md:grid-cols-2 gap-6 mb-8">
          {/* GIF Recording Card */}
          <Card className="bg-white/10 backdrop-blur border-white/20">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-white">
                <Video className="w-5 h-5" />
                GIF Recording
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm text-purple-200">Quality: 85%</label>
                <Slider defaultValue={[85]} max={100} step={1} />
              </div>
              
              <div className="space-y-2">
                <label className="text-sm text-purple-200">Frame Rate: 15 fps</label>
                <Slider defaultValue={[15]} max={60} step={1} />
              </div>
              
              <div className="flex items-center space-x-2">
                <Switch id="optimize" />
                <label htmlFor="optimize" className="text-sm text-purple-200">
                  Optimize for web
                </label>
              </div>
              
              <Button className="w-full bg-red-600 hover:bg-red-700">
                Start Recording
              </Button>
            </CardContent>
          </Card>

          {/* Screenshot Card */}
          <Card className="bg-white/10 backdrop-blur border-white/20">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-white">
                <Camera className="w-5 h-5" />
                Screenshots
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-purple-200">
                Quick screenshot functionality
              </p>
              
              <div className="grid grid-cols-2 gap-2">
                <Button variant="outline" className="border-white/20 text-white">
                  Full Screen
                </Button>
                <Button variant="outline" className="border-white/20 text-white">
                  Select Area
                </Button>
                <Button variant="outline" className="border-white/20 text-white">
                  Active Window
                </Button>
                <Button variant="outline" className="border-white/20 text-white">
                  Custom
                </Button>
              </div>
              
              <Button className="w-full bg-blue-600 hover:bg-blue-700" disabled>
                Coming Soon!
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Recent Captures */}
        <Card className="bg-white/10 backdrop-blur border-white/20">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-white">
              <FolderOpen className="w-5 h-5" />
              Recent Captures
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Sample capture items */}
              <div className="bg-white/5 rounded-lg p-4 border border-white/10">
                <div className="aspect-video bg-gray-700 rounded mb-2 flex items-center justify-center">
                  <span className="text-gray-400">GIF Preview</span>
                </div>
                <p className="text-sm text-white truncate">hyprsnap_20250923_143052.gif</p>
                <p className="text-xs text-purple-200">2.3 MB • 2 min ago</p>
                <Button size="sm" className="w-full mt-2" variant="outline">
                  <Download className="w-4 h-4 mr-1" />
                  Download
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
```

## GTK/Zenity Dialog Mockups (Linux Integration)

### 1. Zenity Progress Dialog
```bash
# Progress dialog for GIF processing
zenity --progress \
  --title="HyprSnap - Processing GIF" \
  --text="Converting video to GIF..." \
  --percentage=0 \
  --auto-close \
  --width=400
```

### 2. YAD Configuration Dialog
```bash
# Settings dialog using YAD
yad --form \
  --title="HyprSnap Settings" \
  --width=500 \
  --height=400 \
  --field="Quality:NUM" 85 \
  --field="Frame Rate:NUM" 15 \
  --field="Optimize for web:CHK" FALSE \
  --field="Output Directory:DIR" "$HOME/Pictures/HyprSnap/Gifs" \
  --field="Copy to clipboard:CHK" TRUE \
  --field="Show notifications:CHK" TRUE
```

### 3. Area Selection Overlay
```
┌─────────────────────────────────────────────────────────────┐
│ HyprSnap - Select Area                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ╔═══════════════════════════════════════════════════════╗  │
│  ║                                                       ║  │
│  ║  Click and drag to select recording area             ║  │
│  ║                                                       ║  │
│  ║  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ║  │
│  ║  │                                                 │  ║  │
│  ║  │           Selected Area                         │  ║  │
│  ║  │           1920 x 1080                           │  ║  │
│  ║  │                                                 │  ║  │
│  ║  └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  ║  │
│  ║                                                       ║  │
│  ║  Press ENTER to confirm, ESC to cancel               ║  │
│  ╚═══════════════════════════════════════════════════════╝  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Notification Mockups

### 1. Recording Started Notification
```
┌─────────────────────────────────────────┐
│ 🎥 HyprSnap                             │
│                                         │
│ Recording started!                      │
│ Press Super+Ctrl+C to stop             │
│                                         │
│ Quality: 85% • FPS: 15                  │
└─────────────────────────────────────────┘
```

### 2. Processing Complete Notification
```
┌─────────────────────────────────────────┐
│ ✅ HyprSnap                             │
│                                         │
│ GIF saved successfully!                 │
│ hyprsnap_20250923_143052.gif (2.3 MB)  │
│                                         │
│ 📋 Copied to clipboard                  │
│ 📁 ~/Pictures/HyprSnap/Gifs/           │
└─────────────────────────────────────────┘
```

### 3. Error Notification
```
┌─────────────────────────────────────────┐
│ ❌ HyprSnap Error                       │
│                                         │
│ Recording failed!                       │
│ Missing dependency: wf-recorder         │
│                                         │
│ Run ./setup.sh to install              │
└─────────────────────────────────────────┘
```

## System Tray Integration (Future)

### Tray Menu Mockup
```
┌─────────────────────────────────────────┐
│ 🎥 Record GIF                           │
│ 📸 Take Screenshot                      │
│ ─────────────────────────────────────── │
│ 📁 Open Captures Folder                │
│ 📋 Recent Captures                  ▶   │
│ ─────────────────────────────────────── │
│ ⚙️ Settings                             │
│ ❓ Help                                 │
│ 🚪 Quit HyprSnap                        │
└─────────────────────────────────────────┘
```

## Mobile/Touch Interface Concept (Future)

### Touch-Friendly Controls
```html
<div class="mobile-interface">
  <div class="capture-buttons">
    <button class="record-btn">
      🎥 Record GIF
    </button>
    <button class="screenshot-btn">
      📸 Screenshot
    </button>
  </div>
  
  <div class="settings-panel">
    <div class="quality-slider">
      <label>Quality</label>
      <input type="range" min="1" max="100" value="85">
    </div>
    <div class="fps-slider">
      <label>Frame Rate</label>
      <input type="range" min="1" max="60" value="15">
    </div>
  </div>
</div>
```

## Accessibility Features

### Screen Reader Compatible Interface
- All UI elements have proper ARIA labels
- Keyboard navigation support
- High contrast mode support
- Voice command integration (future)
- Large text mode compatibility

### Keyboard Shortcuts
- `Ctrl+G`: Start GIF recording
- `Ctrl+S`: Take screenshot
- `Ctrl+Q`: Quit application
- `F1`: Show help
- `Esc`: Cancel current operation
- `Enter`: Confirm selection
- `Space`: Pause/Resume recording

This comprehensive UI mockup collection demonstrates HyprSnap's potential for both command-line and graphical interfaces, ensuring accessibility and modern design principles across all platforms.