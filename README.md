<div align="center">

# 🌌 xNotes Ultimate Pro
### *The Ultra-Premium Glassmorphic Productivity & Power-Study Suite for Android*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)
[![Offline First](https://img.shields.io/badge/Architecture-100%25_Offline-blueviolet?style=for-the-badge&logo=offline-first)]()
[![Security](https://img.shields.io/badge/Biometrics-Hardware_Protected-critical?style=for-the-badge&logo=fingerprint)]()
[![License](https://img.shields.io/badge/License-MIT-success?style=for-the-badge)]()

<p align="center">
  <b>A breathtaking offline workspace blending Liquid Frosted Glassmorphism, Native Hardware Biometrics, an Integrated Code Studio, and a complete University/AL Study Suite.</b>
</p>

[✨ Key Features](#-key-features) •
[📱 App Modules](#-app-modules) •
[🔒 Security & Privacy](#-security--privacy) •
[🚀 Zero-PC Cloud Build](#-zero-pc-cloud-build-github-actions) •
[🛠 Tech Stack](#-tech-stack)

---

</div>

## 🌟 Overview

**xNotes Ultimate Pro** is engineered for high-performance students, software engineers, and power users who demand uncompromising aesthetic elegance paired with strictly private, offline-first reliability. 

Featuring real-time `BackdropFilter` glass blur engines, dynamic ambient mesh backdrops, interactive flashcard memory drills, and automated GPA calculations—it is the all-in-one productivity power suite that never leaks a byte of data to the cloud.

---

## ✨ Key Features

| Category | Highlights |
| :--- | :--- |
| **🎨 UI / UX** | Frosted Glassmorphism, Liquid neon glowing orbs, True OLED Black mode, Stadium Pill buttons |
| **💻 Code Studio** | Line-number gutter, Monospace syntax simulator, One-tap boilerplate snippets, Quick copy |
| **🎓 Study Suite** | 25/5 Pomodoro focus timer, Flip Flashcard review engine, Weekly lecture scheduler |
| **📈 Academics** | Live Exam target days countdown, Semester GPA & Credit hour calculator |
| **🔒 Security** | Native Fingerprint / Face ID unlock, Fallback PIN gate, Encrypted secondary Vault |
| **💾 Persistence** | 100% Local offline storage, One-tap JSON Database Backup/Restore, Offline QR matrix |

---

## 📱 App Modules

### 1. 🎓 All-in-One Power Study Lab
- **⏱️ Embedded Pomodoro Focus Timer:** 25-minute study intervals with live circular glass countdown ring, progress tracking, and session completion counter.
- **🃏 Revision Flashcards:** Flip-card study system for mathematical derivations, definitions, and active recall self-testing.
- **📅 Timetable & Lecture Scheduler:** Weekly lecture grid with subject color badges, hall numbers, and time slots.
- **⏳ Exam Countdown:** Days-remaining visual counter for school, competitive, or university exams.
- **📊 Semester GPA Calculator:** Real-time GPA computation factoring credit hours and grade points.

### 2. 💻 Integrated Code Editor & Markdown Studio
- **Syntax Simulation:** Monospace canvas with a real-time line-number gutter and syntax color accents.
- **Fast Code Injections:** Instant injection templates for `for-loops`, `async functions`, and `class models`.
- **Markdown & ASCII Tables:** Render clean Markdown previews and embedded ASCII/Unicode tables.
- **🧠 3-Line Key Takeaways:** Local extractive summarization algorithm distilling long notes into 3 critical bullet points.

### 3. 🔒 Hardware Biometrics & Vault Protection
- **Fingerprint & Face ID Shield:** Hardware-backed device authentication via `local_auth`.
- **Numpad PIN Fallback:** Custom illuminated glass numpad when biometrics are unavailable.
- **Secret Vault Folder:** Secondary hidden vault protected with a distinct master PIN (`9999`).
- **Incognito Session Mode:** Work in volatile RAM memory—no notes or drafts are saved to disk during active incognito mode.

---

## 🚀 Zero-PC Cloud Build (GitHub Actions)

Don't have a computer? You can build and download the production `.apk` directly to your phone using GitHub Actions:

1. Fork or push this repository to your GitHub account.
2. Ensure `.github/workflows/build.yml` is present in your repo.
3. Navigate to the **Actions** tab on GitHub.
4. Select **Build Flutter APK** ➡️ Click **Run workflow**.
5. Once the run turns **Green (Passed)**, scroll to **Artifacts** and download `xNotes-Pro-App.zip`.
6. Extract the zip on your phone and install `app-release.apk`!

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (v3.x / Latest Stable)
- **Language:** [Dart](https://dart.dev)
- **Local Persistence:** `shared_preferences` & `dart:convert` (Zero remote server dependency)
- **Hardware Security:** `local_auth` (Biometrics / Fingerprint / Face ID)
- **Formatting & Dates:** `intl`
- **Vector Graphics:** Custom offline Canvas Painter (`CustomPainter` for offline QR matrix generation)

---

## 🔐 Privacy Guarantee

- 🚫 **No Tracking / No Analytics**
- 🚫 **No Internet Access Required**
- 🛡️ **100% Offline First:** All notes, flashcards, marks, and vault documents remain strictly on your physical device.

---

<div align="center">

Crafted with ❤️ for Power Users & Developers.

⭐ **Star this repository if you found it useful!**

</div>
