<p align="center">
  <img src="NetatalkUtilityIcon.png" alt="Netatalk Utility Icon" width="120" />
</p>

<h1 align="center">Netatalk Utility</h1>

<p align="center">
  A beautiful, native macOS app to manage your Netatalk service with one click.
</p>

<p align="center">
  <a href="https://github.com/victorlobe/Netatalk-Utility/releases/latest">
    <img alt="Download" src="https://img.shields.io/badge/download-latest-blue?logo=apple" />
  </a>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-007AFF">
  <img alt="Netatalk" src="https://img.shields.io/badge/netatalk-homebrew-blue">
</p>

---

## ✨ Features

- 💡 Start, stop, and restart Netatalk via `brew services`
- 🔄 Live status updates with animation and glow
- 🔧 Auto-installs Netatalk if it's missing
- 📦 Real-time install progress bar with step output
- ⏳ Graceful post-install transition handling
- 🔍 Combined status check using `brew` and `pgrep`
- 🟢/🔴 Optional Dock badge indicator
- 🧭 Menu bar shortcut to open Netatalk config path
- 🧊 Native macOS layout and non-resizable UI
- 🧃 No terminal needed

---

## 📦 Download

👉 [**Download the latest version (.dmg)**](https://github.com/yourusername/netatalk-Utility/releases/latest)

> **Requirements:**
> - macOS 11 or later
> - [Netatalk](https://netatalk.sourceforge.io/) installed via Homebrew:
>
> ```bash
> brew install netatalk
> ```

---

## 🖼️ Screenshots

### ✅ Netatalk is running
<img src="screenshot-running.png" width="700"/>

### 🔴 Netatalk is not running
<img src="screenshot-stopped.png" width="700"/>

---

## ⚙️ Preferences

- Toggle Dock badge visibility from the **View** menu
- Open Netatalk config folder from the **File** menu

---

## 🔧 How It Works

Netatalk Utility uses `brew services` under the hood to control your Netatalk installation.  
It checks status using both `brew services list` and `pgrep`, with graceful fallback.

The UI is built entirely in **Swift + Cocoa**, optimized for clarity and speed.

---

## 🧑‍💻 License

This project is licensed under the [MIT License](LICENSE).

---

## 🧠 Author

Made with ❤️ by [Victor Lobe](https://github.com/victorlobe)
