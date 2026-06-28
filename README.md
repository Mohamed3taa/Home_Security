# 🏠 Nexus — AI-Powered Home Security System

> Graduation Project — Faculty of Computers and Artificial Intelligence  
> Menoufia National University — Academic Year 2025/2026  
> Program: Internet of Things and Big Data Analytics

---

## 👥 Team Members

| Name |
|------|
| Omar Mahmoud AbdElhakim Gomaa |
| Mohammad Ataa Mohammad Elbassal |
| AbdElrahman Ateff Farag Ahmad |
| Yousef Ibrahim Mohammad Mahmoud |
| Mahmoud Mohammad Abdelfatah Mohammad |

**Supervised by:** Dr. Elhossiny Ibrahim

---

## 📌 Project Overview

**Nexus** is a fully integrated, AI-powered home security system that combines real-time video surveillance, intelligent anomaly detection, encrypted live streaming, IoT hardware control, and instant mobile notifications into a single unified platform.

The system consists of three main components:

- 🖥️ **Desktop Application** — Python/PyQt6 surveillance station
- 📱 **Mobile Application** — Flutter cross-platform app (Android/iOS)
- 🔧 **Smart Hardware Device** — ESP32-based IoT controller

---

## ✨ Key Features

- 🤖 **AI Anomaly Detection** using Google Gemini 2.5 Flash — detects intruders, weapons, suspicious behavior, and identifies family members by name
- 📹 **Encrypted Live Video Streaming** via MQTT over TLS with Fernet symmetric encryption
- 🔔 **Instant Push Notifications** with alert snapshots delivered via Firebase Cloud Messaging
- 🚪 **Remote Hardware Control** — gate and alarm management from anywhere via mobile app
- 📊 **Real-time Sensor Monitoring** — temperature and humidity via DHT22 sensor
- 🔐 **QR Code Device Pairing** — zero manual network configuration
- 👨‍👩‍👧 **Family Recognition** — add family member photos for AI-based face recognition
- 🗄️ **Alert History** — full history of AI-generated security events with images

---

## 🏗️ System Architecture

```
┌─────────────────┐     MQTT TLS      ┌─────────────────┐
│  Desktop App    │ ────────────────► │  Mobile App     │
│  (Python/PyQt6) │                   │  (Flutter)      │
└────────┬────────┘                   └────────┬────────┘
         │                                     │
         │         Firebase Platform           │
         └──────────────┬──────────────────────┘
                        │
            ┌───────────┴───────────┐
            │  Firestore Database   │
            │  Firebase Auth        │
            │  Firebase FCM         │
            └───────────┬───────────┘
                        │
               ┌────────┴────────┐
               │  ESP32 Hardware │
               │  (Smart Device) │
               └─────────────────┘
```

---

## 🛠️ Technologies Used

### Desktop Application
| Technology | Purpose |
|------------|---------|
| Python 3.10+ | Core language |
| PyQt6 | Desktop GUI |
| OpenCV | Camera capture and recording |
| paho-mqtt | MQTT streaming |
| Fernet (cryptography) | End-to-end encryption |
| Google Gemini 2.5 Flash | AI anomaly detection |
| Firebase Admin SDK | Server-side Firebase access |
| Cloudinary | Alert snapshot storage |

### Mobile Application
| Technology | Purpose |
|------------|---------|
| Flutter (Dart) | Cross-platform mobile framework |
| Firebase (Auth/Firestore/FCM) | Backend services |
| mqtt_client | Live stream reception |
| encrypt (Fernet) | Video decryption |
| mobile_scanner | QR code pairing |

### Hardware (ESP32)
| Technology | Purpose |
|------------|---------|
| ESP32 DOIT DevKit V1 | Microcontroller |
| FreeRTOS | Multi-task firmware |
| DHT22 | Temperature and humidity sensor |
| Servo Motor | Gate control |
| Buzzer | Alarm system |
| FirebaseClient | Firestore communication |

---

## 📁 Project Structure

```
project/
├── DesktopApp/              # Python Desktop Application
│   ├── codes/
│   │   ├── main.py
│   │   ├── GUI.py
│   │   ├── recorder.py
│   │   ├── streamer.py
│   │   ├── ai_detector.py
│   │   ├── notification_sender.py
│   │   ├── crypto_manager.py
│   │   ├── config.py
│   │   └── Requirements.txt
│
├── home_security/           # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── models/
│   │   └── notification/
│   └── pubspec.yaml
│
├── smart device/            # ESP32 Hardware Firmware
│   ├── src/
│   │   ├── main.cpp
│   │   ├── config.h
│   │   ├── Firebase/
│   │   ├── Sensor/
│   │   ├── Gate/
│   │   └── Buzzer/
│   └── platformio.ini
│
└── Simulators/              # Hardware Testing Tools
```

---

## ⚙️ Setup and Installation

### Desktop Application

```bash
# 1. Install dependencies
pip install -r DesktopApp/codes/Requirements.txt

# 2. Add your Firebase Admin SDK credentials file to DesktopApp/
# 3. Configure DesktopApp/codes/config.py with your API keys
# 4. Run the application
python DesktopApp/codes/main.py
```

### Mobile Application

```bash
# 1. Install Flutter dependencies
cd home_security
flutter pub get

# 2. Add google-services.json to android/app/
# 3. Build and run
flutter run
```

### Hardware Firmware

```bash
# 1. Open smart device/ in VS Code with PlatformIO
# 2. Configure src/config.h with your WiFi and Firebase credentials
# 3. Connect ESP32 via USB and upload firmware
```

---

## 🔧 Hardware Pin Configuration

| Component | ESP32 GPIO Pin |
|-----------|----------------|
| Servo Motor (Gate) | GPIO 4 |
| DHT22 Sensor | GPIO 17 |
| Buzzer | GPIO 19 |

---

## 🔒 Security Notes

- All video streams are encrypted using **Fernet symmetric encryption** before transmission
- MQTT communication uses **TLS on port 8883**
- Device credentials are shared exclusively via **QR code** — never transmitted over the network
- Copy `config.py.example` and fill in your own API keys before running

---

## 📊 Performance Results

| Metric | Result |
|--------|--------|
| Live stream latency | 0.8 – 1.5 seconds |
| AI detection accuracy | ~90% |
| Push notification delivery | 2 – 4 seconds |
| Hardware command execution | ~3 seconds |
| UAT satisfaction rating | 4.2 / 5.0 |

---

## 📄 License

This project was developed as a graduation thesis for academic purposes at Menoufia National University.
