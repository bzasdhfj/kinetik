<div align="center">
  <img src="CheckInApp/Assets.xcassets/AppIcon.appiconset/mac_512.png" width="128" height="128" alt="Kinetik Logo">
  <h1>Kinetik</h1>
  <p><b>A beautiful, native macOS habit tracker built with SwiftUI.</b></p>

  <p>
    <a href="https://github.com/bzasdhfj/kinetik/stargazers"><img src="https://img.shields.io/github/stars/bzasdhfj/kinetik?style=for-the-badge&color=teal" alt="Stars"></a>
    <a href="https://github.com/bzasdhfj/kinetik/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License"></a>
    <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-5.9-orange.svg?style=for-the-badge" alt="Swift"></a>
    <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14.0+-black.svg?style=for-the-badge&logo=apple" alt="macOS"></a>
  </p>
</div>

<br>

**Kinetik** is a lightning-fast, ultra-lightweight macOS desktop application designed for pure self-discipline and habit tracking. Built natively with SwiftUI, it stands as a rebellion against bloated web-wrapper apps. It consumes practically zero memory, collects absolutely **zero user data**, and keeps your focus exactly where it belongs: on your daily goals.

## ✨ Why Kinetik?

- 🔒 **100% Privacy & Zero Tracking**: Your data belongs to you. Everything is stored locally on your Mac's file system. No cloud syncing, no analytics, no accounts, and absolutely zero telemetry.
- ⚡️ **Ultra-Lightweight**: Built purely with native macOS technologies. No Electron, no web views. It consumes a fraction of the memory of typical apps and launches instantly.
- 🎯 **Pure Self-Discipline**: A focused environment for your daily routines. Differentiate between "Required" core habits and optional "Bonus" tasks to maintain an honest streak.
- 💎 **Uncompromised Native Design**: While performance is the priority, aesthetics aren't sacrificed. Features translucent `GlassBackground`, smooth spring animations, and native haptic feedback that feels perfectly at home on macOS.
- 🧩 **Always-on Desktop Widgets**: Keep your check-in heatmap on your desktop. Your progress is always just a glance away, seamlessly integrated with your workspace.

## 📸 Screenshots

*(Replace these with your actual screenshots when publishing)*

| Main Dashboard | Desktop Widget |
| :---: | :---: |
| <img src="https://github.com/user-attachments/assets/ec0f8b08-ac2f-4f0d-ab0c-5004fe7506dc" width="400"> | <img src="https://github.com/user-attachments/assets/e82aa03e-7866-4311-9748-225e03125b80" width="200"> |

### Prerequisites
- **macOS 14.0 (Sonoma)** or later.
- **Xcode 15.0** or later (if building from source).

### Building from source
1. Clone the repository:
   ```bash
   git clone https://github.com/bzasdhfj/kinetik.git
   ```
2. Open `CheckInApp.xcodeproj` in Xcode.
3. Select the `CheckInApp` scheme and hit `Cmd + R` to build and run!

## 🛠 Tech Stack

- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Persistence**: Local JSON Storage (Shared Container for App & Widget)
- **Extensions**: WidgetKit, AppIntents (for interactive widgets)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/bzasdhfj/kinetik/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <sub>Built with ❤️ by an independent developer.</sub>
</div>
