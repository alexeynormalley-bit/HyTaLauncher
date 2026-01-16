
# HyTa Launcher (Linux Port)

**This is a Hytale Crack / Launcher for Linux.**

A modern, monochrome Hytale launcher for Linux, built with Flutter.

![Screenshot](preview.png?raw=true)

## Features

- **Native Linux Support**: Designed specifically for Linux distributions (Fedora, Ubuntu, etc.).
- **Monochrome UI**: A sleek, distraction-free interface.
- **Mod Management**: 
  - Manage installed mods easily.
  - **Manual Import**: Drag and drop or select `.jar`/`.zip` files to install them instantly.
- **Smart Updates**: Only downloads game files when a new version is detected.
- **Advanced Logs**: View and copy game logs directly from the "LOGS" tab (with error highlighting).
- **Settings**: Configure RAM allocation, launch flags, and other parameters.
- **Force Close**: Ability to forcibly terminate the game process if needed.
- **Secure**: No hardcoded API keys or sensitive data.

## Installation

### AppImage (Recommended)
Download the latest `.AppImage` from the [Releases](https://github.com/alexeynormalley-bit/HyTaLauncher/releases) page, make it executable, and run.

```bash
chmod +x HyTaLauncher-Linux.AppImage
./HyTaLauncher-Linux.AppImage
```

### Building from Source

Requirements:
- Flutter SDK
- Clang/CMake
- GTK development headers

```bash
git clone https://github.com/alexeynormalley-bit/HyTaLauncher.git
cd HyTaLauncher/hyta_launcher
flutter pub get
flutter run -d linux
```

## Usage

1. **Login**: Enter your player name (Offline mode supported).
2. **Play**: Select your version and branch, then click PLAY.
3. **Mods**: 
   - Manage existing mods in the "MODS" tab.
   - Import new mods via the "IMPORT" tab.
4. **Logs**: Check the "LOGS" tab for game output and errors.

## Made With Antigravity (Claude 4.5 Opus, Gemini 3 Pro)

## License

MIT License.
