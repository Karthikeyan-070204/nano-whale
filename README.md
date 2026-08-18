# 🐳 Nano Whale - Lightweight Docker TUI

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com/Vriddhachalam/nano-whale/releases)

<p align="center">
  <img src="img/nano_whale_w_bg.png" alt="Nano Whale logo">
</p>

**Nano Whale** is a blazingly fast, lightweight **Terminal User Interface (TUI)** for managing Docker containers, images, and volumes. Completely rewritten from the ground up in native C++, it requires **zero external dependencies** (no Python, no Node.js, no Bun) and compiles to a single ~1MB standalone binary.

---

## ✨ Features

- **🚀 Zero Dependencies**: Runs as a single native C++ binary executable.
- **⚡ Blazingly Fast**: Built with `FTXUI` for instant startup, zero interpreter overhead, and ultra-low memory usage.
- **🖥️ Cross-Platform**: Native support for Windows (WSL2 integration), Linux, and macOS.
- **⌨️ Keyboard-Driven**: Efficient VIM-style navigation and shortcuts.
- **🛠️ Power Tools**:
    - **Dashboard**: View running and stopped containers.
    - **Deep Inspector**: Real-time CPU, Memory, and Network I/O metrics graphing.
    - **Quick Shell**: Drop into an interactive container shell (`/bin/sh` or `/bin/bash`) instantly (`t`).
    - **File Explorer**: Browse a container's filesystem and download files directly to your host machine.
    - **Docker Compose**: Manage `docker-compose.yml` environments directly from the TUI with live log streaming.
    - **System Prune**: Clean up dangling images, unused containers, and dead volumes.
    - **True-Color ASCII Art**: Beautiful half-block terminal rendering of the Nano Whale logo.

---

## 📦 Installation & Build

You will need `CMake` and a modern C++ compiler (supports C++17).

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/Karthikeyan-070204/nano-whale.git
   cd nano-whale
   ```

2. Configure and build using CMake:
   ```bash
   cmake -B build
   cmake --build build
   ```

3. Run the compiled binary:
   ```bash
   ./build/nano-whale
   ```
   *(On Windows using MSVC, the path might be `.\build\Debug\nano-whale.exe` or `.\build\Release\nano-whale.exe`)*

### Using Pre-built Binaries
Pre-built binaries for Windows, Linux, and macOS are automatically generated. You can download them directly from the [Releases page](https://github.com/Karthikeyan-070204/nano-whale/releases).

---

## 🚀 Usage

Ensure your Docker daemon is running, then simply launch the app:

```bash
# If you are in the repository folder:
./build/nano-whale
```

---

## ⌨️ Keyboard Shortcuts

### Navigation
| Key | Action |
|-----|--------|
| `Tab` / `Left/Right` | Switch between Top Tabs (Dashboard, Compose, Prune, About) |
| `↑/↓` | Navigate lists and menus |
| `PageUp/Down` | Scroll lists faster |

### Actions
| Key | Action |
|-----|--------|
| `Enter` | **Inspect** / Expand details / Enter File Explorer |
| `s` | **Start** container |
| `x` | **Stop** container |
| `r` | **Restart** container |
| `d` | **Delete** (Container/Image/Volume) |
| `l` | **Fullscreen Logs** (Live stream) |
| `t` | **Exec** (Enter shell inside container) |
| `F5` | **Manual Refresh** (Reload all data) |
| `q` or `Esc` | **Go Back** / **Quit** |

---

## 💻 Development

Built using **C++17** and **[FTXUI](https://github.com/ArthurSonzogni/FTXUI)**.

### Generating ASCII Art
If you want to update the ASCII art logo in the About tab, you can use the provided Python script:
```bash
python generate_ascii.py
```
This will automatically parse the PNG image and regenerate `src/ascii_art.h` using half-block Unicode characters for high-resolution terminal rendering.

---

## 🤝 Contributing
Contributions are welcome! Please submit a Pull Request.

## 📜 License
MIT License - see [LICENSE](LICENSE) for details.

---
**Made with ❤️ by Vriddhachalam S**
*Swim fast, stay light! 🐳*
