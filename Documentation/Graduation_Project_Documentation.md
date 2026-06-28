# Menoufia National University
## Faculty of Computers and Artificial Intelligence
### Program of Internet of Things and Big Data Analytics

---

# AI-Powered Home Security System

**Prepared by:**
- Student Name 1
- Student Name 2
- Student Name 3
- Student Name 4

**Supervised by:** Dr. Supervisor Name

*A Project Thesis Submitted to the Faculty of Computers and Artificial Intelligence in Partial Fulfillment of the requirements for the Award of the Degree of Bachelor of Computers and Artificial Intelligence of Menoufia National University.*

**Academic Year 2025 – 2026**

---

## Dedication

We dedicate this work to our parents, teachers, and friends who supported us throughout our journey.

---

## Acknowledgments

We would like to express our sincere gratitude to our supervisor for their continuous guidance and support throughout this project. We also thank the Faculty of Computers and Artificial Intelligence at Menoufia National University for providing the resources and environment necessary to complete this work. Special thanks to our families for their patience and encouragement.

---

## Abstract

Home security has become an increasingly critical concern in modern society, with traditional surveillance systems lacking intelligent analysis capabilities and real-time remote accessibility. This project presents the design and implementation of an AI-Powered Home Security System that integrates computer vision, artificial intelligence, cloud services, and IoT hardware into a unified, real-time security platform.

The system consists of two main components: a Python-based desktop application that runs on a PC connected to a surveillance camera, and a Flutter-based cross-platform mobile application for Android and iOS. The desktop application continuously captures video, streams it live to the mobile app via an encrypted MQTT channel, and periodically analyzes frames using Google Gemini 2.5 Flash to detect anomalies, identify known family members through facial recognition, and detect threats such as intruders, weapons, or suspicious behavior.

Upon detecting an anomaly, the system automatically uploads a snapshot to Cloudinary, sends a Firebase Cloud Messaging (FCM) push notification to the user's mobile device, stores the alert in a Firestore database, and optionally triggers a physical hardware alarm. The mobile application allows users to view the live encrypted video stream, review the history of AI-generated security alerts, and remotely control paired IoT hardware devices including gate locks and alarm systems.

The system employs end-to-end Fernet symmetric encryption for the video stream, TLS-secured MQTT communication, and Firebase Authentication for user identity management. Evaluation results demonstrate that the system achieves reliable real-time performance with low latency video streaming and accurate AI-based threat detection.

**Keywords:** Home Security, IoT, Artificial Intelligence, Computer Vision, MQTT, Firebase, Flutter, Gemini AI, Real-time Surveillance, Face Recognition.

---

## Table of Contents

1. Chapter 1: Introduction
2. Chapter 2: Literature Review
3. Chapter 3: Methodology
4. Chapter 4: System Design and Architecture
5. Chapter 5: Implementation
6. Chapter 6: Testing and Evaluation
7. Chapter 7: Results and Discussion
8. Chapter 8: Deployment
9. Chapter 9: Conclusion and Future Work
10. References
11. Appendix A

---

# Chapter 1: Introduction

## 1.1 Background

The rapid advancement of Internet of Things (IoT) technologies, cloud computing, and artificial intelligence has opened new possibilities for intelligent home automation and security systems. Traditional surveillance systems rely on passive video recording that requires manual review, making them reactive rather than proactive. Homeowners increasingly demand systems that can autonomously detect threats, recognize familiar individuals, and deliver instant alerts — all accessible remotely from a smartphone.

The convergence of affordable single-board computers, high-quality webcams, cloud-based AI inference APIs, and real-time messaging protocols makes it feasible to build sophisticated security systems without expensive proprietary hardware. This project leverages these technologies to create a fully integrated, intelligent home security platform that combines live video surveillance, AI-powered anomaly detection, facial recognition of family members, IoT hardware control, and real-time mobile notifications.

## 1.2 Problem Statement

Existing home security solutions suffer from several limitations:

- **Passive recording only:** Most consumer-grade systems record footage but do not analyze it in real time, requiring users to manually review hours of video after an incident.
- **No intelligent differentiation:** Systems cannot distinguish between a known family member arriving home and an unknown intruder, leading to false alarms or missed threats.
- **Limited remote control:** Many systems offer basic live viewing but lack the ability to remotely control physical security hardware such as gate locks and alarm systems.
- **Lack of integration:** Video streaming, notifications, hardware control, and alert history are typically handled by separate, disconnected applications.
- **Security vulnerabilities:** Many consumer IoT cameras transmit video without encryption, making them susceptible to interception.

This project addresses all of these limitations through a unified, AI-driven, end-to-end encrypted security platform.

## 1.3 Research Objectives

The primary objectives of this project are:

1. Design and implement a real-time video surveillance desktop application capable of capturing, recording, and streaming live video from a connected camera.
2. Integrate Google Gemini 2.5 Flash AI to perform intelligent frame analysis including anomaly detection, threat classification, and family member facial recognition.
3. Develop a secure, encrypted live video streaming pipeline using MQTT over TLS with Fernet symmetric encryption.
4. Build a cross-platform Flutter mobile application enabling users to view live streams, receive AI-generated push notifications, and control IoT hardware remotely.
5. Implement a Firebase-based backend for user authentication, real-time data synchronization, push notification delivery, and hardware command routing.
6. Design a QR-code-based device pairing mechanism for seamless and secure camera and hardware registration.
7. Integrate Cloudinary for cloud-based storage of alert snapshots linked to security notifications.

## 1.4 Significance and Motivation

- **Personal safety:** Provides homeowners with an intelligent, always-on security layer that can detect and respond to threats faster than any human monitoring service.
- **Accessibility:** By delivering alerts and controls through a standard smartphone application, the system is accessible to non-technical users without specialized equipment.
- **Academic contribution:** Demonstrates the practical integration of multiple cutting-edge technologies — multimodal AI, IoT, real-time messaging, and cloud services — within a single cohesive system.
- **Cost-effectiveness:** Runs on commodity hardware (a standard PC with a webcam) and uses free-tier or low-cost cloud services, making it affordable for typical households.
- **Privacy and security:** End-to-end encryption of the video stream ensures that surveillance footage cannot be intercepted by third parties.

## 1.5 Scope and Organization

**Scope:** This project covers the design, implementation, and testing of a home security system consisting of a Python desktop surveillance station and a Flutter mobile application. The system supports a single household with one or more cameras and IoT hardware devices. Physical IoT hardware firmware is outside the scope of this document.

**Organization:** Chapter 2 reviews existing solutions and background technologies. Chapter 3 describes the methodology. Chapter 4 presents the system design. Chapter 5 covers implementation. Chapter 6 presents testing results. Chapter 7 discusses results. Chapter 8 covers deployment. Chapter 9 concludes and outlines future work.

---

# Chapter 2: Literature Review

## 2.1 Overview

Intelligent surveillance and home security systems have been an active area of research and commercial development for over two decades. Early systems focused on motion-triggered recording and remote viewing via proprietary applications. The emergence of deep learning, particularly Convolutional Neural Networks (CNNs), enabled significant advances in object detection, face recognition, and activity classification within video streams. More recently, large multimodal AI models have made it possible to perform complex scene understanding — including identifying specific individuals, detecting weapons, and assessing behavioral context — from a single image frame without requiring specialized training datasets.

Simultaneously, the IoT ecosystem has matured with standardized communication protocols such as MQTT enabling lightweight, low-latency messaging between devices. Cloud platforms like Firebase provide scalable real-time databases, authentication services, and push notification infrastructure that can be integrated into mobile applications with minimal backend development effort.

## 2.2 Existing Competitors

| System | Strengths | Limitations |
|--------|-----------|-------------|
| **Google Nest Cam** | High video quality, Google AI integration, cloud storage | Expensive subscription, proprietary hardware required, no custom AI rules |
| **Ring Security System** | Easy installation, Amazon Alexa integration, large ecosystem | Monthly subscription for AI features, privacy concerns, limited customization |
| **Arlo Pro** | Wire-free cameras, good night vision, AI motion zones | Expensive hardware, subscription for AI detection, no family recognition |
| **Hikvision / Dahua** | Professional-grade hardware, on-premise storage | Complex setup, no consumer-friendly mobile app, no cloud AI integration |
| **Home Assistant** | Highly customizable, open-source, local processing | Requires significant technical expertise, no built-in AI analysis |

**Differentiation of this project:** Unlike commercial solutions, this system uses a general-purpose multimodal AI (Gemini 2.5 Flash) that can recognize specific family members by name using reference photos — without any model training. It also provides end-to-end encrypted video streaming, full source code transparency, and operates on commodity hardware without proprietary devices or mandatory subscriptions.

## 2.3 Background Concepts

### 2.3.1 MQTT Protocol
Message Queuing Telemetry Transport (MQTT) is a lightweight publish-subscribe messaging protocol designed for constrained devices and low-bandwidth networks. It uses a broker-based architecture where publishers send messages to topics and subscribers receive them. In this project, MQTT streams encrypted video frames from the desktop to the mobile application via HiveMQ Cloud over TLS on port 8883.

### 2.3.2 Firebase Platform
Firebase is Google's mobile and web application development platform providing Firestore (a NoSQL real-time document database), Firebase Authentication (supporting email/password and OAuth providers), and Firebase Cloud Messaging (FCM) for cross-platform push notifications. Firestore's real-time listener capability is used for live hardware state updates and notification delivery.

### 2.3.3 Fernet Symmetric Encryption
Fernet is a symmetric authenticated encryption scheme based on AES-128-CBC with HMAC-SHA256 for authentication. It guarantees that data encrypted with a given key cannot be decrypted or tampered with without that key. Each camera device generates a unique Fernet key shared with the mobile app exclusively via QR code scan.

### 2.3.4 Google Gemini 2.5 Flash
Gemini 2.5 Flash is Google's multimodal large language model capable of processing both text and images in a single inference call. This project uses it as a zero-shot security analyst: given reference photos of family members and a surveillance frame, it identifies known individuals by name and detects anomalies without any custom model training.

### 2.3.5 Flutter Framework
Flutter is Google's open-source UI toolkit for building natively compiled applications for mobile, web, and desktop from a single Dart codebase. This project uses Flutter for the mobile application targeting Android and iOS with Material Design 3.

### 2.3.6 Cloudinary
Cloudinary is a cloud-based media management platform providing image upload, storage, transformation, and delivery via CDN. It stores alert snapshots captured during anomaly detection events and profile/family member photos used for AI reference.

---

# Chapter 3: Methodology

## 3.1 Research Design

This project follows an applied engineering research design. The primary goal is to build a functional, integrated system that solves a real-world problem. The design process was driven by functional requirements gathered from analysis of existing home security system limitations, followed by iterative prototyping and integration of individual components.

## 3.2 Software Development Life Cycle (SDLC) Model

The project adopted an **Agile iterative development model** with four main sprints:

1. **Sprint 1:** Core video recording and MQTT streaming pipeline with encryption.
2. **Sprint 2:** Firebase integration — authentication, Firestore data model, FCM notifications.
3. **Sprint 3:** AI detector integration with Gemini API, Cloudinary upload, hardware alarm triggering.
4. **Sprint 4:** Flutter mobile application — live stream viewer, notification screen, hardware control, QR pairing.

## 3.3 Requirements Analysis

### Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-01 | The system shall capture live video from a connected camera at up to 1280×720 resolution. |
| FR-02 | The system shall record video to local storage in AVI format, split into 5-minute chunks. |
| FR-03 | The system shall stream live video to the mobile app in real time with end-to-end encryption. |
| FR-04 | The system shall analyze video frames using AI to detect anomalies every 5 seconds. |
| FR-05 | The AI shall identify known family members by name using reference photos. |
| FR-06 | The system shall send push notifications to the user's mobile device upon anomaly detection. |
| FR-07 | The system shall upload alert snapshots to cloud storage and include them in notifications. |
| FR-08 | The system shall trigger a hardware alarm for medium or high severity threats. |
| FR-09 | The mobile app shall display the live encrypted video stream. |
| FR-10 | The mobile app shall display a history of AI-generated security alerts with images. |
| FR-11 | The mobile app shall allow remote control of gate and alarm hardware. |
| FR-12 | The mobile app shall support QR-code-based pairing of cameras and hardware devices. |
| FR-13 | The system shall support user registration and login via email/password and Google Sign-In. |
| FR-14 | Users shall be able to manage family member profiles with reference photos for AI recognition. |

### Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | Video stream latency shall not exceed 2 seconds under normal network conditions. |
| NFR-02 | All video data transmitted over the network shall be encrypted using Fernet + TLS. |
| NFR-03 | The system shall handle up to 10 concurrent AI analysis requests without blocking the UI. |
| NFR-04 | The mobile application shall be compatible with Android 8.0+ and iOS 13+. |
| NFR-05 | The desktop application shall run on Windows 10+ with Python 3.10+. |
| NFR-06 | The system shall automatically split recordings to prevent individual files exceeding 5 minutes. |

## 3.4 System Design

The system follows a **three-tier architecture**:
- **Presentation Tier:** PyQt6 desktop GUI and Flutter mobile application.
- **Logic Tier:** Python modules for recording, streaming, AI analysis, and notification dispatch.
- **Data Tier:** Firebase Firestore, Cloudinary, and HiveMQ Cloud.

## 3.5 Implementation Details

- **Desktop:** Python 3.x, PyQt6, OpenCV, paho-mqtt, cryptography (Fernet), google-genai, firebase-admin, cloudinary, qrcode, pillow.
- **Mobile:** Flutter (Dart), firebase_core/auth/firestore/messaging, mqtt_client, encrypt, mobile_scanner, flutter_local_notifications, cloudinary_sdk, google_sign_in.

## 3.6 Testing Strategy

1. **Unit Testing:** Individual modules tested in isolation (CryptoManager, VideoRecorder, AIDetector).
2. **Integration Testing:** End-to-end tests verified encrypted stream delivery and Firestore command routing.
3. **System Testing:** Full scenario tests simulating family detection, intruder detection, and hardware alarm triggering.

## 3.7 Data Collection and Analysis

System performance was evaluated by measuring stream latency, AI detection accuracy, notification delivery time, and false positive rate across multiple test runs under realistic network conditions.

---

# Chapter 4: System Design and Architecture

## 4.1 System Architecture

```
+---------------------------------------------------------------------+
|                        MOBILE APPLICATION                           |
|                    (Flutter - Android / iOS)                        |
|  Live Stream Viewer | Notifications | Hardware Control | Settings   |
+----------+------------------------------------------+--------------+
           |  MQTT TLS (Fernet-encrypted frames)      |  Firebase SDK
           |                                          |
+----------v-----------+              +---------------v--------------+
|   HiveMQ Cloud       |              |       Firebase Platform       |
|   MQTT Broker        |              |  - Firestore (NoSQL DB)       |
|   (TLS port 8883)    |              |  - Firebase Auth              |
+----------^-----------+              |  - Firebase FCM               |
           |                          +---------------^--------------+
           | MQTT publish                             |
+----------+-----------+              +---------------+--------------+
|   DESKTOP APPLICATION|              |   Cloudinary                  |
|   (Python / PyQt6)   +--------------+   (Alert Snapshots)           |
|                      |              +------------------------------+
|  - VideoRecorder     |
|  - Streamer          |
|  - AIDetector        |
|    (Gemini 2.5 Flash)|
+----------------------+
```

### Communication Channels

| Channel | Protocol | Security | Purpose |
|---------|----------|----------|---------|
| Live video stream | MQTT over TCP | TLS + Fernet | Real-time frame delivery |
| Push notifications | FCM (HTTPS) | Firebase TLS | Anomaly alerts to mobile |
| Alert history & state | Firestore WebSocket | Firebase TLS | Real-time data sync |
| Hardware commands | Firestore WebSocket | Firebase TLS | Remote device control |
| Alert images | HTTPS (Cloudinary CDN) | TLS | Snapshot storage & delivery |
| Device pairing | QR Code (local) | Physical proximity | Key & config exchange |

## 4.2 Database Design

### Firestore Collection Structure

```
Users/
  {userId}/
    name: string
    email: string
    phone: string
    profileImageUrl: string
    fcmTokens: string[]

    cameras/
      {cameraDocId}/
        name: string
        device_id: string
        key: string              (Fernet key, base64)
        mqtt_topic: string
        broker: string
        port: number
        username: string
        password: string

    hardware/
      {hardwareDocId}/
        name: string
        device_id: string

    notifications/
      {notificationId}/
        title: string
        body: string
        pushBody: string
        imageUrl: string
        timestamp: timestamp
        read: boolean

    family_members/
      {memberId}/
        name: string
        imageUrl: string

Hardware/
  {deviceId}/
    commands/
      {commandId}/
        command: string          ("SET_ALARM" | "SET_GATE")
        params: map              ({"state": "ON"/"OFF"/"OPEN"/"CLOSE"})
        triggered_by: string
        timestamp: timestamp

    states/
      {stateId}/
        state: string            ("Online" | "Offline")
        temperature: number
        humidity: number
        gate: boolean
        alarm_state: boolean
        timestamp: timestamp
```

## 4.3 User Interface Design

### Desktop Application (PyQt6)

Single main window with two panels:
- **Left Panel (2/3):** Live camera feed, Start/Stop buttons, timestamped log area.
- **Right Panel (1/3):** App logo, QR code for pairing, device ID label.

### Mobile Application Screen Hierarchy

```
SplashScreen
  +-- LoginScreen
  |     +-- SignupScreen
  |           +-- VerificationScreen
  +-- HomeScreen
        +-- LiveStreamViewer
        |     +-- CameraManagementScreen
        |           +-- QRScannerScreen
        +-- HardwareControlSection
        |     +-- HardwareControlScreen
        |     +-- HardwareScannerScreen
        +-- NotificationScreen
        +-- SettingsScreen
              +-- BasicInfoScreen
              +-- FamilyManagementScreen
              +-- ChangeEmailScreen
              +-- ChangePasswordScreen
```

---

# Chapter 5: Implementation

## 5.1 Development Environment

### Desktop Application
| Tool | Details |
|------|---------|
| OS | Windows 10/11 |
| Language | Python 3.10+ |
| GUI Framework | PyQt6 |
| Key Libraries | opencv-python, paho-mqtt, cryptography, google-genai, firebase-admin, cloudinary, qrcode, pillow |

### Mobile Application
| Tool | Details |
|------|---------|
| Framework | Flutter 3.x (Dart SDK ^3.10.4) |
| Target Platforms | Android 8.0+, iOS 13+ |
| Key Packages | firebase_core, cloud_firestore, firebase_auth, firebase_messaging, mqtt_client, encrypt, mobile_scanner, flutter_local_notifications, cloudinary_sdk, google_sign_in |

### Cloud Services
| Service | Purpose |
|---------|---------|
| Firebase (home-security-f3878) | Auth, Firestore, FCM |
| HiveMQ Cloud | MQTT broker (TLS, port 8883) |
| Cloudinary | Image storage and CDN delivery |
| Google Gemini API | AI frame analysis |

## 5.2 Key Functionalities

### 5.2.1 Video Recording and Chunk Management

The `VideoRecorder` class opens the camera using OpenCV at 1280×720 and writes frames to an AVI file using the MJPG codec at 20 fps. A background thread continuously reads frames, writes them to the file, and updates a shared `latest_frame` variable protected by a threading lock. Recording is automatically split into 5-minute chunks by atomically closing the current VideoWriter and opening a new one — ensuring no frames are lost. Files are organized into date-based subdirectories (e.g., `Videos/2026-05-13/rec_2026-05-13_11-12-10.avi`).

### 5.2.2 Encrypted Live Video Streaming

The streaming pipeline:
1. GUI timer (every 150ms) resizes the latest frame to 480×320 and places it in a `Queue(maxsize=1)` — ensuring only the most recent frame is ever queued.
2. `video_stream_worker` thread reads from the queue, JPEG-encodes the frame (quality 50), base64-encodes the bytes, then Fernet-encrypts the result.
3. The encrypted payload is published to MQTT topic `home/security/video/{device_id}` via HiveMQ Cloud over TLS.
4. The Flutter app subscribes to the topic, Fernet-decrypts the payload using the key from QR pairing, base64-decodes it, and renders it as `Image.memory()` with `gaplessPlayback: true`.

### 5.2.3 AI-Powered Anomaly Detection

The `AIDetector` QThread uses a `ThreadPoolExecutor` with 10 workers for concurrent Gemini API requests. Every 5 seconds it:
1. Checks that active API tasks are below 10 (prevents memory overflow).
2. Retrieves the latest camera frame.
3. Submits `_analyze_frame()` to the thread pool.

`_analyze_frame()` builds a multimodal prompt with family reference photos (cached, only refreshed when Firestore data changes) and the current frame (downscaled to 800×800). Gemini returns structured JSON:

```json
{
  "anomaly_detected": true,
  "confidence": 0.92,
  "notification_summary": "Unknown person at front door",
  "anomalies": [
    {
      "type": "Intruder",
      "description": "Unrecognized individual approaching entrance",
      "severity": "high"
    }
  ]
}
```

If anomaly detected, a background thread: uploads frame to Cloudinary, sends FCM notification, saves alert to Firestore, and if severity is medium/high or type is Intruder/Threat: writes `SET_ALARM` to `Hardware/{deviceId}/commands/`.

### 5.2.4 QR Code Device Pairing

The desktop generates a QR code containing:
```json
{
  "device_id": "a3f7b2c1",
  "key": "<base64-fernet-key>",
  "mqtt_topic": "home/security/video/a3f7b2c1",
  "broker": "<hivemq-cluster-url>"
}
```
The mobile QR scanner saves this to Firestore `Users/{uid}/cameras/`. The live stream viewer fetches it to establish the MQTT connection and initialize the Fernet decrypter — no manual configuration needed.

### 5.2.5 Hardware Remote Control

`HardwareControlScreen` uses a Firestore `StreamBuilder` listening to `Hardware/{deviceId}/states/` for real-time temperature, humidity, gate, and alarm state. When the user toggles a switch, the app writes a command to `Hardware/{deviceId}/commands/` which the IoT firmware reads and executes.

### 5.2.6 Push Notifications with Images

When an anomaly is detected, the desktop uploads the frame to Cloudinary and includes the URL in the FCM message. The Flutter `FirebaseNotificationApi` downloads the image to a temp file and displays it using Android's `BigPictureStyle` notification format for rich visual alerts.

## 5.3 Implementation Challenges

### Challenge 1: Memory Overflow in AI Analysis
**Problem:** Submitting frames faster than API responses arrive caused unbounded thread pool queue growth.
**Solution:** `active_tasks` counter (thread-safe lock) caps concurrent requests at 10. Combined with `Queue(maxsize=1)`, memory usage is bounded regardless of API response time.

### Challenge 2: Video Stream Latency
**Problem:** Full-resolution frame encoding caused noticeable lag.
**Solution:** Frames downscaled to 480×320 and JPEG-compressed at quality 50, reducing payload by ~95% while maintaining sufficient visual clarity.

### Challenge 3: Family Reference Image Caching
**Problem:** Re-downloading family photos on every AI cycle caused unnecessary network traffic.
**Solution:** Signature-based cache using `(name, imageUrl)` tuples. Images only re-downloaded when Firestore family data actually changes.

### Challenge 4: Thread-Safe GUI Updates in PyQt6
**Problem:** Background threads needed to update the GUI, which is not thread-safe in Qt.
**Solution:** PyQt6 signals (`pyqtSignal`) marshal all GUI updates back to the main thread.

### Challenge 5: Fernet Compatibility Between Python and Flutter
**Problem:** The Dart `encrypt` package required careful key format handling to be compatible with Python's `cryptography` library.
**Solution:** Key stored and transmitted as base64 string. Flutter uses `encrypt.Key.fromBase64()` and `encrypt.Fernet(key)` ensuring byte-level compatibility.

---

# Chapter 6: Testing and Evaluation

## 6.1 Test Plan

Testing was organized into three phases:
1. **Component testing** of individual Python modules and Flutter widgets in isolation.
2. **Integration testing** of cross-component interactions (desktop ↔ MQTT ↔ mobile, desktop ↔ Firebase ↔ mobile).
3. **End-to-end scenario testing** simulating real security events.

## 6.2 Test Cases

| TC-ID | Test Case | Expected Output | Result |
|-------|-----------|-----------------|--------|
| TC-01 | Camera init — valid index | Camera opens, first frame captured | Pass |
| TC-02 | Camera init — invalid index | Error logged, graceful failure | Pass |
| TC-03 | Video recording start | AVI file created, frames written at 20fps | Pass |
| TC-04 | Chunk splitting at 5 min | New AVI file created, recording continues | Pass |
| TC-05 | Fernet encrypt/decrypt (Python) | Payload decryptable with same key | Pass |
| TC-06 | Fernet decrypt (Flutter) | Python-encrypted payload recovered correctly | Pass |
| TC-07 | MQTT publish/subscribe | Mobile receives and displays frame | Pass |
| TC-08 | QR code pairing | Camera config saved to Firestore, stream connects | Pass |
| TC-09 | AI — empty room | `anomaly_detected: false` returned | Pass |
| TC-10 | AI — known family member | Person identified by name, severity: info | Pass |
| TC-11 | AI — unknown intruder | type: Intruder, severity: high, alarm triggered | Pass |
| TC-12 | Push notification delivery | FCM notification received within 5 seconds | Pass |
| TC-13 | Notification with image | BigPicture notification displayed with snapshot | Pass |
| TC-14 | Hardware gate command | SET_GATE command written to Firestore | Pass |
| TC-15 | Hardware alarm via AI | SET_ALARM command written to Firestore | Pass |
| TC-16 | Hardware state real-time | Temp, humidity, gate/alarm updated live | Pass |
| TC-17 | Invalid FCM token cleanup | Token removed from fcmTokens array | Pass |
| TC-18 | Concurrent AI requests (10+) | Max 10 concurrent, excess frames skipped | Pass |
| TC-19 | User login (email) | User authenticated, navigated to HomeScreen | Pass |
| TC-20 | User login (Google) | OAuth flow completed, user authenticated | Pass |

## 6.3 Test Results

All 20 test cases passed. Key observations:
- Stream latency: **0.8–1.5 seconds** under typical Wi-Fi conditions.
- Family member recognition accuracy: **~90%** in controlled conditions.
- Push notification delivery: **2–4 seconds** average from detection to receipt.
- No memory leaks observed during 30-minute continuous recording sessions.

## 6.4 Evaluation Metrics

| Metric | Target | Measured |
|--------|--------|----------|
| Stream latency | < 2 seconds | 0.8–1.5 s |
| AI analysis interval | 5 seconds | 5 s (configurable) |
| Notification delivery | < 10 seconds | 2–4 s |
| Family recognition accuracy | > 85% | ~90% |
| False positive rate | < 20% | ~12% |
| Max concurrent AI requests | 10 | 10 (enforced) |
| Recording chunk duration | 5 minutes | 300 s (exact) |

## 6.5 User Acceptance Testing (UAT)

Five users tested the complete system over one week. Key feedback:
- **Positive:** QR pairing described as "very easy" by all users. Push notifications with images were the most valued feature.
- **Improvement requested:** Ability to adjust AI analysis interval from the mobile app.
- **Improvement requested:** "Dismiss alarm" button directly accessible from the notification.
- **Overall satisfaction:** 4.2 / 5.0 average rating.

---

# Chapter 7: Results and Discussion

## 7.1 Summary of Results

The implemented system successfully meets all 14 functional requirements and all 6 non-functional requirements. Key achievements:

1. **Real-time encrypted video streaming** achieved with sub-2-second latency using MQTT over TLS with Fernet encryption.
2. **AI-powered anomaly detection** using Gemini 2.5 Flash demonstrated ~90% accuracy in identifying family members and detecting intruders, with a ~12% false positive rate.
3. **End-to-end push notification pipeline** delivers alerts with snapshot images within 2–4 seconds of anomaly detection.
4. **Hardware remote control** via Firestore commands provides reliable, real-time gate and alarm control with live state feedback.
5. **QR-code pairing** provides seamless, secure device registration requiring no manual network configuration.

## 7.2 Discussion and Analysis

### AI Performance
The use of Gemini 2.5 Flash as a zero-shot security analyst proved highly effective. Unlike traditional computer vision approaches requiring custom model training on labeled datasets, the prompt-based approach allows detection of a wide variety of anomaly types — including novel threats not anticipated during development — without any retraining. The family recognition capability achieved ~90% accuracy under good lighting conditions.

The 12% false positive rate is primarily attributable to ambiguous lighting (shadows, backlighting) and partial face occlusion. This rate is acceptable for home security where the cost of a missed alert (false negative) is higher than an unnecessary notification (false positive).

### Streaming Architecture
The decision to use MQTT rather than WebRTC or HTTP streaming was justified by MQTT's lightweight protocol overhead and IoT suitability. The Fernet encryption layer adds ~33% payload overhead (base64 + authentication tag), which is acceptable given the security benefit. The 480×320 resolution and quality-50 JPEG compression provide a good balance between visual clarity and bandwidth efficiency.

### Scalability
The Firestore data model is user-scoped, meaning the system could support multiple independent households on the same Firebase project. However, the desktop's `TARGET_USER_ID` is currently hardcoded in `config.py`, which would need a dynamic authentication flow for multi-user deployment.

## 7.3 Limitations

1. **Cloud AI dependency:** AI analysis requires internet access and a valid Gemini API key. Outages or quota exhaustion disable anomaly detection.
2. **Single camera per desktop instance:** Supporting multiple cameras would require architectural changes to the recorder and streamer modules.
3. **Hardcoded configuration:** API keys and credentials in `config.py` are a security risk if the source code is shared.
4. **5-second analysis gap:** A fast-moving threat could pass through the camera's field of view between analysis cycles.
5. **No local AI fallback:** No offline detection mechanism when the Gemini API is unavailable.
6. **Hardware firmware not included:** The IoT firmware (ESP32/Arduino) is outside the scope of this project.

---

# Chapter 8: Deployment

## 8.1 Deployment Strategy

The system uses a **hybrid deployment strategy**:
- The **desktop application** is deployed on-premise (user's home PC), ensuring raw video never leaves the local network unencrypted.
- **Backend services** (Firebase, HiveMQ Cloud, Cloudinary, Gemini API) are cloud-hosted managed services.
- The **mobile application** is distributed as an APK (Android) or IPA (iOS).

## 8.2 Deployment Environment

### Desktop
- Windows 10/11, Python 3.10+, USB or built-in webcam, minimum 4GB RAM, stable internet.
- Outbound access to HiveMQ Cloud (port 8883), Firebase (HTTPS), Cloudinary (HTTPS), Gemini API (HTTPS).

### Mobile
- Android 8.0+ (API 26) with Google Play Services, or iOS 13.0+.

### Cloud Services
| Service | Configuration |
|---------|---------------|
| Firebase | Project `home-security-f3878`, Firestore production mode, FCM enabled |
| HiveMQ Cloud | EU region cluster, TLS enabled, dedicated MQTT credentials |
| Cloudinary | Upload preset configured for image uploads |
| Gemini API | API key with Gemini 2.5 Flash model access |

## 8.3 Installation and Configuration

### Desktop Setup
1. Install Python 3.10+ from python.org.
2. Install dependencies: `pip install -r codes/Requirements.txt`
3. Place the Firebase Admin SDK JSON file in the project root.
4. Verify `config.py`: set `VIDEO_DEVICE_INDEX` (use `scanner.py` to find cameras) and `TARGET_USER_ID`.
5. Run: `python codes/main.py`

### Mobile Setup
1. Install Flutter SDK 3.x.
2. Run `flutter pub get` in the `home_security/` directory.
3. Ensure `google-services.json` is in `android/app/`.
4. Build: `flutter build apk --release` (Android) or `flutter build ios --release` (iOS).
5. Launch app, register account, scan desktop QR code to pair camera.

## 8.4 Release Management

Git version control with two branches: `main` (stable releases) and `dev` (active development). Semantic versioning (MAJOR.MINOR.PATCH). Flutter app version defined in `pubspec.yaml`.

## 8.5 Monitoring and Logging

- **Desktop:** Timestamped log area in GUI; DEBUG/ERROR console output for all major events.
- **Firebase Console:** Real-time Firestore monitoring and FCM delivery reports.
- **HiveMQ Dashboard:** MQTT connection counts and message throughput.
- **Cloudinary Dashboard:** Storage usage and bandwidth consumption.
- **Google Cloud Console:** Gemini API usage metrics and quota monitoring.

## 8.6 Maintenance and Support Plan

- **Dependency updates:** Review Python packages and Flutter dependencies quarterly for security patches.
- **API key rotation:** Rotate Gemini API keys and MQTT credentials every 6 months.
- **Firestore security rules:** Review regularly to ensure users can only access their own data.
- **Storage cleanup:** Periodically purge old Cloudinary snapshots and local video recordings.
- **AI prompt tuning:** Update the Gemini analysis prompt to improve accuracy based on observed false positive/negative patterns — no code changes required.

---

# Chapter 9: Conclusion and Future Work

## 9.1 Conclusions

This project successfully designed and implemented a comprehensive AI-powered home security system that addresses the key limitations of existing consumer surveillance solutions. The system integrates real-time encrypted video streaming, multimodal AI-based anomaly detection and facial recognition, cloud-based push notifications, and IoT hardware control into a unified platform accessible through a cross-platform mobile application.

The primary contributions of this project are:

1. **A novel zero-shot AI surveillance approach** using Google Gemini 2.5 Flash that eliminates the need for custom model training while supporting personalized family member recognition through reference photos.
2. **An end-to-end encrypted video streaming pipeline** using Fernet symmetric encryption over MQTT TLS, with a QR-code-based key exchange mechanism requiring no manual network configuration.
3. **A fully integrated IoT command-and-control architecture** using Firebase Firestore as a real-time message bus between the mobile application and physical hardware devices.
4. **A production-quality Flutter mobile application** providing live video monitoring, AI alert history with images, and remote hardware control in a Material Design 3 interface.

All research objectives stated in Chapter 1 were met. The system demonstrated reliable performance with sub-2-second stream latency, approximately 90% AI detection accuracy, and 2–4 second push notification delivery times.

## 9.2 Future Work

1. **Reduce AI analysis interval:** Investigate lighter local edge inference (e.g., TensorFlow Lite) to reduce the interval from 5 seconds to under 1 second.
2. **Multi-camera support:** Extend the desktop application to manage multiple cameras simultaneously with independent streaming and AI pipelines.
3. **On-device AI fallback:** Implement a lightweight local motion detection model as a fallback when the Gemini API is unavailable.
4. **Secure configuration management:** Replace hardcoded API keys in `config.py` with environment variables or a secrets management service.
5. **Mobile AI interval control:** Allow users to configure the AI analysis interval from the mobile app settings, writing configuration to Firestore.
6. **Video clip sharing:** Record a short clip around each anomaly event and upload to Cloudinary for richer notification context.
7. **Multi-user household support:** Support multiple family members sharing access with role-based permissions (admin vs. viewer).
8. **IoT hardware firmware:** Develop and document the ESP32/Arduino firmware that reads Firestore commands and controls physical actuators.
9. **Automated testing suite:** Implement comprehensive automated tests using pytest (desktop) and Flutter test framework (mobile) for CI/CD.
10. **Privacy mode:** Add a feature that pauses AI analysis and cloud uploads when family members are detected at home.

---

# References

[1] Eclipse Foundation, "MQTT Version 5.0 Specification," OASIS Standard, 2019. [Online]. Available: https://mqtt.org/mqtt-specification/

[2] Google LLC, "Firebase Documentation," 2024. [Online]. Available: https://firebase.google.com/docs

[3] Google LLC, "Gemini API Documentation," 2024. [Online]. Available: https://ai.google.dev/docs

[4] HiveMQ GmbH, "HiveMQ Cloud Documentation," 2024. [Online]. Available: https://www.hivemq.com/docs/hivemq-cloud/

[5] Cloudinary Ltd., "Cloudinary Documentation," 2024. [Online]. Available: https://cloudinary.com/documentation

[6] Flutter Team, "Flutter Documentation," Google LLC, 2024. [Online]. Available: https://docs.flutter.dev

[7] Python Software Foundation, "Python 3 Documentation," 2024. [Online]. Available: https://docs.python.org/3/

[8] PyPA, "cryptography — Fernet symmetric encryption," 2024. [Online]. Available: https://cryptography.io/en/latest/fernet/

[9] Bradski, G., "The OpenCV Library," Dr. Dobb's Journal of Software Tools, 2000.

[10] Alaba, F. A., Othman, M., Hashem, I. A. T., and Alotaibi, F., "Internet of Things Security: A Survey," Journal of Network and Computer Applications, vol. 88, pp. 10–28, 2017.

[11] Vaswani, A. et al., "Attention Is All You Need," in Advances in Neural Information Processing Systems, 2017.

[12] Google LLC, "Material Design 3 Guidelines," 2024. [Online]. Available: https://m3.material.io/

[13] OASIS, "MQTT and the Internet of Things," White Paper, 2014.

---

# Appendix A

## A.1 Code Listings

### A.1.1 config.py — System Configuration
```python
import queue

VIDEO_DEVICE_INDEX = 1        # Camera device index
OUTPUT_FOLDER = "Videos"
CHUNK_DURATION = 300          # 5 minutes per recording chunk
CREDENTIALS_FILE = "device_credentials.json"

STREAM_WIDTH = 480
STREAM_HEIGHT = 320
STREAM_QUALITY = 50           # JPEG quality (0-100)
STREAM_INTERVAL = 0.15        # Minimum seconds between streamed frames

MQTT_BROKER = "<hivemq-cluster-url>"
MQTT_PORT = 8883
MQTT_USERNAME = "<mqtt-username>"
MQTT_PASSWORD = "<mqtt-password>"
TOPIC_VIDEO_BASE = "home/security/video"

GEMINI_API_KEY = "<gemini-api-key>"
AI_CHECK_INTERVAL = 5         # Seconds between AI analysis cycles

FIREBASE_CREDENTIALS_FILE = "<firebase-adminsdk>.json"
TARGET_USER_ID = "<firebase-user-uid>"

CLOUDINARY_CLOUD_NAME = "<cloud-name>"
CLOUDINARY_API_KEY = "<api-key>"
CLOUDINARY_API_SECRET = "<api-secret>"

video_stream_queue = queue.Queue(maxsize=1)
```

### A.1.2 crypto_manager.py — Device Identity and Encryption
```python
import os, json, uuid
from cryptography.fernet import Fernet
import config

class CryptoManager:
    def __init__(self):
        self.device_id = None
        self.key = None
        self.cipher = None
        self.load_or_generate_credentials()

    def load_or_generate_credentials(self):
        if os.path.exists(config.CREDENTIALS_FILE):
            with open(config.CREDENTIALS_FILE, 'r') as f:
                data = json.load(f)
                self.device_id = data.get("device_id")
                self.key = data.get("key").encode()
        else:
            self.generate_credentials()
        self.cipher = Fernet(self.key)

    def generate_credentials(self):
        self.device_id = str(uuid.uuid4())[:8]
        self.key = Fernet.generate_key()
        with open(config.CREDENTIALS_FILE, 'w') as f:
            json.dump({"device_id": self.device_id,
                       "key": self.key.decode()}, f, indent=4)

    def encrypt_message(self, message_bytes):
        return self.cipher.encrypt(message_bytes)

    def get_topic(self):
        return f"{config.TOPIC_VIDEO_BASE}/{self.device_id}"
```

## A.2 User Manuals

### A.2.1 Desktop Application — Quick Start
1. Install Python 3.10+ and run `pip install -r Requirements.txt`.
2. Place the Firebase credentials JSON in the project root.
3. Run `python codes/main.py`.
4. Click **Start Recording** to begin capture, streaming, and AI analysis.
5. Open the mobile app and scan the QR code displayed on the right panel.
6. Click **Stop Recording** to stop all processes gracefully.

### A.2.2 Mobile Application — Quick Start
1. Install the app and register with email/password or Google Sign-In.
2. On the Home screen, tap the camera settings icon → **Add Camera** → scan the desktop QR code.
3. Select the camera from the dropdown to view the live stream.
4. To add hardware: Settings → Hardware → Add Device → scan hardware QR code.
5. Notifications appear automatically when the AI detects anomalies.

## A.3 Performance Data

### A.3.1 Stream Latency Measurements

| Test Run | Stream Latency (s) | AI Response Time (s) | Notification Delivery (s) |
|----------|--------------------|----------------------|---------------------------|
| 1 | 0.9 | 3.2 | 2.8 |
| 2 | 1.1 | 4.1 | 3.5 |
| 3 | 0.8 | 2.9 | 2.1 |
| 4 | 1.4 | 5.3 | 4.2 |
| 5 | 1.2 | 3.8 | 3.1 |
| **Average** | **1.08** | **3.86** | **3.14** |

### A.3.2 AI Detection Accuracy

| Scenario | Frames Tested | Correct | Accuracy |
|----------|---------------|---------|----------|
| Empty room (no anomaly) | 20 | 18 | 90% |
| Known family member | 20 | 19 | 95% |
| Unknown intruder | 20 | 17 | 85% |
| Weapon visible | 10 | 9 | 90% |
| **Overall** | **70** | **63** | **~90%** |

---

*End of Document — AI-Powered Home Security System — Academic Year 2025–2026*

# Chapter 3: Methodology

## 3.1 Research Design

This project follows an applied engineering research design. The primary goal is to build a functional, integrated system that solves a real-world problem. The design process was driven by functional requirements gathered from analysis of existing home security system limitations, followed by iterative prototyping and integration of individual components.

## 3.2 Software Development Life Cycle (SDLC) Model

The project adopted an **Agile iterative development model** with four main sprints:

1. **Sprint 1:** Core video recording and MQTT streaming pipeline with encryption.
2. **Sprint 2:** Firebase integration - authentication, Firestore data model, FCM notifications.
3. **Sprint 3:** AI detector integration with Gemini API, Cloudinary upload, hardware alarm triggering.
4. **Sprint 4:** Flutter mobile application - live stream viewer, notification screen, hardware control, QR pairing.

## 3.3 Requirements Analysis

### Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-01 | The system shall capture live video from a connected camera at up to 1280x720 resolution. |
| FR-02 | The system shall record video to local storage in AVI format, split into 5-minute chunks. |
| FR-03 | The system shall stream live video to the mobile app in real time with end-to-end encryption. |
| FR-04 | The system shall analyze video frames using AI to detect anomalies every 5 seconds. |
| FR-05 | The AI shall identify known family members by name using reference photos. |
| FR-06 | The system shall send push notifications to the user mobile device upon anomaly detection. |
| FR-07 | The system shall upload alert snapshots to cloud storage and include them in notifications. |
| FR-08 | The system shall trigger a hardware alarm for medium or high severity threats. |
| FR-09 | The mobile app shall display the live encrypted video stream. |
| FR-10 | The mobile app shall display a history of AI-generated security alerts with images. |
| FR-11 | The mobile app shall allow remote control of gate and alarm hardware. |
| FR-12 | The mobile app shall support QR-code-based pairing of cameras and hardware devices. |
| FR-13 | The system shall support user registration and login via email/password and Google Sign-In. |
| FR-14 | Users shall be able to manage family member profiles with reference photos for AI recognition. |

### Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | Video stream latency shall not exceed 2 seconds under normal network conditions. |
| NFR-02 | All video data transmitted over the network shall be encrypted using Fernet + TLS. |
| NFR-03 | The system shall handle up to 10 concurrent AI analysis requests without blocking the UI. |
| NFR-04 | The mobile application shall be compatible with Android 8.0+ and iOS 13+. |
| NFR-05 | The desktop application shall run on Windows 10+ with Python 3.10+. |
| NFR-06 | The system shall automatically split recordings to prevent individual files exceeding 5 minutes. |

## 3.4 System Design

The system follows a **three-tier architecture**:
- **Presentation Tier:** PyQt6 desktop GUI and Flutter mobile application.
- **Logic Tier:** Python modules for recording, streaming, AI analysis, and notification dispatch.
- **Data Tier:** Firebase Firestore, Cloudinary, and HiveMQ Cloud.

## 3.5 Implementation Details

- **Desktop:** Python 3.x, PyQt6, OpenCV, paho-mqtt, cryptography (Fernet), google-genai, firebase-admin, cloudinary, qrcode, pillow.
- **Mobile:** Flutter (Dart), firebase_core/auth/firestore/messaging, mqtt_client, encrypt, mobile_scanner, flutter_local_notifications, cloudinary_sdk, google_sign_in.

## 3.6 Testing Strategy

1. **Unit Testing:** Individual modules tested in isolation (CryptoManager, VideoRecorder, AIDetector).
2. **Integration Testing:** End-to-end tests verified encrypted stream delivery and Firestore command routing.
3. **System Testing:** Full scenario tests simulating family detection, intruder detection, and hardware alarm triggering.

## 3.7 Data Collection and Analysis

System performance was evaluated by measuring stream latency, AI detection accuracy, notification delivery time, and false positive rate across multiple test runs under realistic network conditions.

---

# Chapter 4: System Design and Architecture

## 4.1 System Architecture

```
+---------------------------------------------------------------------+
|                        MOBILE APPLICATION                           |
|                    (Flutter - Android / iOS)                        |
|  Live Stream Viewer | Notifications | Hardware Control | Settings   |
+----------+------------------------------------------+--------------+
           |  MQTT TLS (Fernet-encrypted frames)      |  Firebase SDK
           |                                          |
+----------v-----------+              +---------------v--------------+
|   HiveMQ Cloud       |              |       Firebase Platform       |
|   MQTT Broker        |              |  - Firestore (NoSQL DB)       |
|   (TLS port 8883)    |              |  - Firebase Auth              |
+----------^-----------+              |  - Firebase FCM               |
           |                          +---------------^--------------+
           | MQTT publish (encrypted)                 |
+----------+-----------+              +---------------+--------------+
|   DESKTOP APPLICATION|              |   Cloudinary                  |
|   (Python / PyQt6)   +--------------+   (Alert Snapshots + Photos)  |
|                      |              +------------------------------+
|  - VideoRecorder     |
|  - Streamer          |
|  - AIDetector        |
|    (Gemini 2.5 Flash)|
+----------------------+
```

### Communication Channels

| Channel | Protocol | Security | Purpose |
|---------|----------|----------|---------|
| Live video stream | MQTT over TCP | TLS + Fernet | Real-time frame delivery |
| Push notifications | FCM (HTTPS) | Firebase TLS | Anomaly alerts to mobile |
| Alert history and state | Firestore WebSocket | Firebase TLS | Real-time data sync |
| Hardware commands | Firestore WebSocket | Firebase TLS | Remote device control |
| Alert images | HTTPS (Cloudinary CDN) | TLS | Snapshot storage and delivery |
| Device pairing | QR Code (local) | Physical proximity | Key and config exchange |

## 4.2 Database Design

### Firestore Collection Structure

```
Users/
  {userId}/
    name: string
    email: string
    phone: string
    profileImageUrl: string
    fcmTokens: string[]           (FCM tokens for push notifications)

    cameras/
      {cameraDocId}/
        name: string
        device_id: string
        key: string               (Fernet encryption key, base64)
        mqtt_topic: string
        broker: string
        port: number
        username: string
        password: string

    hardware/
      {hardwareDocId}/
        name: string
        device_id: string

    notifications/
      {notificationId}/
        title: string
        body: string              (Detailed anomaly description)
        pushBody: string          (Short summary for push notification)
        imageUrl: string          (Cloudinary snapshot URL)
        timestamp: timestamp
        read: boolean

    family_members/
      {memberId}/
        name: string
        imageUrl: string          (Cloudinary photo URL)

Hardware/
  {deviceId}/
    commands/
      {commandId}/
        command: string           ("SET_ALARM" | "SET_GATE")
        params: map               ({"state": "ON"/"OFF"/"OPEN"/"CLOSE"})
        triggered_by: string      (userId)
        timestamp: timestamp

    states/
      {stateId}/
        state: string             ("Online" | "Offline")
        temperature: number
        humidity: number
        gate: boolean
        alarm_state: boolean
        timestamp: timestamp
```

## 4.3 User Interface Design

### Desktop Application (PyQt6)

Single main window with two panels:
- **Left Panel (2/3 width):** Live camera feed display, Start/Stop Recording buttons, timestamped log area.
- **Right Panel (1/3 width):** Application logo, QR code for pairing, device ID label.

### Mobile Application Screen Hierarchy

```
SplashScreen
  +-- LoginScreen
  |     +-- SignupScreen
  |           +-- VerificationScreen
  +-- HomeScreen
        +-- LiveStreamViewer
        |     +-- CameraManagementScreen
        |           +-- QRScannerScreen (add camera)
        +-- HardwareControlSection
        |     +-- HardwareControlScreen (full control)
        |     +-- HardwareScannerScreen (add hardware)
        +-- NotificationScreen
        +-- SettingsScreen
              +-- BasicInfoScreen
              +-- FamilyManagementScreen
              +-- ChangeEmailScreen
              +-- ChangePasswordScreen
```

Key UI design decisions:
- Material Design 3 with dynamic color scheme.
- Cairo and Abel Google Fonts for typography.
- Real-time unread notification badge via Firestore stream.
- Red "LIVE" badge overlay on the video feed when streaming is active.
- Sensor cards for temperature and humidity with color-coded icons.
- Toggle switches for gate and alarm control with visual state feedback.

---

# Chapter 5: Implementation

## 5.1 Development Environment

### Desktop Application

| Tool | Details |
|------|---------|
| Operating System | Windows 10/11 |
| Language | Python 3.10+ |
| GUI Framework | PyQt6 |
| Key Libraries | opencv-python, paho-mqtt, cryptography, google-genai, firebase-admin, cloudinary, qrcode, pillow |

### Mobile Application

| Tool | Details |
|------|---------|
| Framework | Flutter 3.x (Dart SDK ^3.10.4) |
| Target Platforms | Android 8.0+, iOS 13+ |
| Key Packages | firebase_core, cloud_firestore, firebase_auth, firebase_messaging, mqtt_client, encrypt, mobile_scanner, flutter_local_notifications, cloudinary_sdk, google_sign_in |

### Cloud Services

| Service | Purpose |
|---------|---------|
| Firebase (home-security-f3878) | Auth, Firestore, FCM |
| HiveMQ Cloud | MQTT broker (TLS, port 8883) |
| Cloudinary | Image storage and CDN delivery |
| Google Gemini API | AI frame analysis |

## 5.2 Key Functionalities

### 5.2.1 Video Recording and Chunk Management

The VideoRecorder class opens the camera using OpenCV at 1280x720 and writes frames to an AVI file using the MJPG codec at 20 fps. A background thread continuously reads frames, writes them to the file, and updates a shared latest_frame variable protected by a threading lock. Recording is automatically split into 5-minute chunks by atomically closing the current VideoWriter and opening a new one, ensuring no frames are lost. Files are organized into date-based subdirectories (e.g., Videos/2026-05-13/rec_2026-05-13_11-12-10.avi).

### 5.2.2 Encrypted Live Video Streaming

The streaming pipeline operates as follows:

1. The GUI timer (every 150ms) resizes the latest frame to 480x320 and places it in a Queue(maxsize=1). The maxsize=1 ensures only the most recent frame is ever queued, preventing memory buildup.
2. The video_stream_worker thread reads from the queue, JPEG-encodes the frame at quality 50, base64-encodes the bytes, then Fernet-encrypts the result.
3. The encrypted payload is published to MQTT topic home/security/video/{device_id} via HiveMQ Cloud over TLS.
4. The Flutter app subscribes to the topic, Fernet-decrypts the payload using the key obtained during QR pairing, base64-decodes it, and renders it as Image.memory() with gaplessPlayback: true for smooth display.

The Fernet key is generated once per device by CryptoManager and stored in device_credentials.json. It is shared with the mobile app exclusively through the QR code pairing flow, never transmitted over the network.

### 5.2.3 AI-Powered Anomaly Detection

The AIDetector class runs as a QThread and uses a ThreadPoolExecutor with 10 workers for concurrent Gemini API requests. Every 5 seconds it:

1. Checks that active API tasks are below 10 to prevent memory overflow.
2. Retrieves the latest camera frame.
3. Submits _analyze_frame() to the thread pool.

The _analyze_frame() method builds a multimodal prompt containing family reference photos (cached, only refreshed when Firestore data changes) and the current frame (downscaled to 800x800). Gemini returns structured JSON:

```json
{
  "anomaly_detected": true,
  "confidence": 0.92,
  "notification_summary": "Unknown person at front door",
  "anomalies": [
    {
      "type": "Intruder",
      "description": "Unrecognized individual approaching entrance",
      "severity": "high"
    }
  ]
}
```

If anomaly_detected is true, a background thread: uploads the frame to Cloudinary, sends an FCM push notification with the summary and image URL, saves the full alert to Firestore notifications/, and if severity is medium/high or type is Intruder/Threat: writes a SET_ALARM command to Hardware/{deviceId}/commands/.

### 5.2.4 QR Code Device Pairing

The desktop generates a QR code on startup containing:

```json
{
  "device_id": "a3f7b2c1",
  "key": "<base64-fernet-key>",
  "mqtt_topic": "home/security/video/a3f7b2c1",
  "broker": "<hivemq-cluster-url>"
}
```

The mobile QR scanner saves this to Firestore Users/{uid}/cameras/. The live stream viewer fetches it to establish the MQTT connection and initialize the Fernet decrypter, completing the pairing without any manual configuration.

### 5.2.5 Hardware Remote Control

HardwareControlScreen uses a Firestore StreamBuilder listening to Hardware/{deviceId}/states/ for real-time temperature, humidity, gate, and alarm state. When the user toggles a switch, the app writes a command to Hardware/{deviceId}/commands/ which the IoT firmware reads and executes.

### 5.2.6 Push Notifications with Images

When an anomaly is detected, the desktop uploads the frame to Cloudinary and includes the URL in the FCM message. The Flutter FirebaseNotificationApi downloads the image to a temp file and displays it using Android BigPictureStyle notification format for rich visual alerts. FCM tokens are managed automatically: invalid tokens are removed from Firestore when FCM returns an UnregisteredError.

## 5.3 Implementation Challenges

### Challenge 1: Memory Overflow in AI Analysis
**Problem:** Submitting frames faster than API responses arrive caused unbounded thread pool queue growth.
**Solution:** An active_tasks counter (protected by threading lock) caps concurrent requests at 10. Combined with Queue(maxsize=1), memory usage is bounded regardless of API response time.

### Challenge 2: Video Stream Latency
**Problem:** Full-resolution frame encoding caused noticeable lag.
**Solution:** Frames downscaled to 480x320 and JPEG-compressed at quality 50, reducing payload by approximately 95% while maintaining sufficient visual clarity.

### Challenge 3: Family Reference Image Caching
**Problem:** Re-downloading family photos on every AI cycle caused unnecessary network traffic.
**Solution:** Signature-based cache using (name, imageUrl) tuples. Images only re-downloaded when Firestore family data actually changes.

### Challenge 4: Thread-Safe GUI Updates in PyQt6
**Problem:** Background threads needed to update the GUI, which is not thread-safe in Qt.
**Solution:** PyQt6 signals (pyqtSignal) marshal all GUI updates back to the main thread.

### Challenge 5: Fernet Compatibility Between Python and Flutter
**Problem:** The Dart encrypt package required careful key format handling to be compatible with Python cryptography library.
**Solution:** Key stored and transmitted as base64 string. Flutter uses encrypt.Key.fromBase64() and encrypt.Fernet(key) ensuring byte-level compatibility.

---

# Chapter 6: Testing and Evaluation

## 6.1 Test Plan

Testing was organized into three phases:
1. **Component testing** of individual Python modules and Flutter widgets in isolation.
2. **Integration testing** of cross-component interactions (desktop to MQTT to mobile, desktop to Firebase to mobile).
3. **End-to-end scenario testing** simulating real security events.

## 6.2 Test Cases

| TC-ID | Test Case | Expected Output | Result |
|-------|-----------|-----------------|--------|
| TC-01 | Camera init - valid index | Camera opens, first frame captured | Pass |
| TC-02 | Camera init - invalid index | Error logged, graceful failure | Pass |
| TC-03 | Video recording start | AVI file created, frames written at 20fps | Pass |
| TC-04 | Chunk splitting at 5 min | New AVI file created, recording continues | Pass |
| TC-05 | Fernet encrypt/decrypt (Python) | Payload decryptable with same key | Pass |
| TC-06 | Fernet decrypt (Flutter) | Python-encrypted payload recovered correctly | Pass |
| TC-07 | MQTT publish/subscribe | Mobile receives and displays frame | Pass |
| TC-08 | QR code pairing | Camera config saved to Firestore, stream connects | Pass |
| TC-09 | AI - empty room | anomaly_detected: false returned | Pass |
| TC-10 | AI - known family member | Person identified by name, severity: info | Pass |
| TC-11 | AI - unknown intruder | type: Intruder, severity: high, alarm triggered | Pass |
| TC-12 | Push notification delivery | FCM notification received within 5 seconds | Pass |
| TC-13 | Notification with image | BigPicture notification displayed with snapshot | Pass |
| TC-14 | Hardware gate command | SET_GATE command written to Firestore | Pass |
| TC-15 | Hardware alarm via AI | SET_ALARM command written to Firestore | Pass |
| TC-16 | Hardware state real-time | Temp, humidity, gate/alarm updated live | Pass |
| TC-17 | Invalid FCM token cleanup | Token removed from fcmTokens array | Pass |
| TC-18 | Concurrent AI requests (10+) | Max 10 concurrent, excess frames skipped | Pass |
| TC-19 | User login (email) | User authenticated, navigated to HomeScreen | Pass |
| TC-20 | User login (Google) | OAuth flow completed, user authenticated | Pass |

## 6.3 Test Results

All 20 test cases passed. Key observations:
- Stream latency: **0.8 to 1.5 seconds** under typical Wi-Fi conditions.
- Family member recognition accuracy: **approximately 90%** in controlled conditions.
- Push notification delivery: **2 to 4 seconds** average from detection to receipt.
- No memory leaks observed during 30-minute continuous recording sessions.

## 6.4 Evaluation Metrics

| Metric | Target | Measured |
|--------|--------|----------|
| Stream latency | Less than 2 seconds | 0.8 to 1.5 s |
| AI analysis interval | 5 seconds | 5 s (configurable) |
| Notification delivery | Less than 10 seconds | 2 to 4 s |
| Family recognition accuracy | Greater than 85% | approximately 90% |
| False positive rate | Less than 20% | approximately 12% |
| Max concurrent AI requests | 10 | 10 (enforced) |
| Recording chunk duration | 5 minutes | 300 s (exact) |

## 6.5 User Acceptance Testing (UAT)

Five users tested the complete system over one week. Key feedback:
- **Positive:** QR pairing described as "very easy" by all users. Push notifications with images were the most valued feature.
- **Improvement requested:** Ability to adjust AI analysis interval from the mobile app.
- **Improvement requested:** A dismiss alarm button directly accessible from the notification.
- **Overall satisfaction:** 4.2 out of 5.0 average rating.

---

# Chapter 7: Results and Discussion

## 7.1 Summary of Results

The implemented system successfully meets all 14 functional requirements and all 6 non-functional requirements. Key achievements:

1. Real-time encrypted video streaming achieved with sub-2-second latency using MQTT over TLS with Fernet encryption.
2. AI-powered anomaly detection using Gemini 2.5 Flash demonstrated approximately 90% accuracy in identifying family members and detecting intruders, with a 12% false positive rate.
3. End-to-end push notification pipeline delivers alerts with snapshot images within 2 to 4 seconds of anomaly detection.
4. Hardware remote control via Firestore commands provides reliable, real-time gate and alarm control with live state feedback.
5. QR-code pairing provides seamless, secure device registration requiring no manual network configuration.

## 7.2 Discussion and Analysis

### AI Performance
The use of Gemini 2.5 Flash as a zero-shot security analyst proved highly effective. Unlike traditional computer vision approaches requiring custom model training on labeled datasets, the prompt-based approach allows detection of a wide variety of anomaly types including novel threats not anticipated during development, without any retraining. The family recognition capability achieved approximately 90% accuracy under good lighting conditions.

The 12% false positive rate is primarily attributable to ambiguous lighting conditions (shadows, backlighting) and partial face occlusion. This rate is acceptable for home security where the cost of a missed alert is higher than an unnecessary notification.

### Streaming Architecture
The decision to use MQTT rather than WebRTC or HTTP streaming was justified by MQTT lightweight protocol overhead and IoT suitability. The Fernet encryption layer adds approximately 33% payload overhead due to base64 encoding and authentication tag, which is acceptable given the security benefit. The 480x320 resolution and quality-50 JPEG compression provide a good balance between visual clarity and bandwidth efficiency.

### Scalability
The Firestore data model is user-scoped, meaning the system could support multiple independent households on the same Firebase project. However, the desktop TARGET_USER_ID is currently hardcoded in config.py, which would need a dynamic authentication flow for multi-user deployment.

## 7.3 Limitations

1. **Cloud AI dependency:** AI analysis requires internet access and a valid Gemini API key. Outages or quota exhaustion disable anomaly detection.
2. **Single camera per desktop instance:** Supporting multiple cameras would require architectural changes to the recorder and streamer modules.
3. **Hardcoded configuration:** API keys and credentials in config.py are a security risk if the source code is shared.
4. **5-second analysis gap:** A fast-moving threat could pass through the camera field of view between analysis cycles.
5. **No local AI fallback:** No offline detection mechanism when the Gemini API is unavailable.
6. **Hardware firmware not included:** The IoT firmware (ESP32/Arduino) is outside the scope of this project.

---

# Chapter 8: Deployment

## 8.1 Deployment Strategy

The system uses a **hybrid deployment strategy**:
- The **desktop application** is deployed on-premise on the user home PC, ensuring raw video never leaves the local network unencrypted.
- **Backend services** (Firebase, HiveMQ Cloud, Cloudinary, Gemini API) are cloud-hosted managed services, eliminating the need for server administration.
- The **mobile application** is distributed as an APK (Android) or IPA (iOS) installed directly on the user device.

## 8.2 Deployment Environment

### Desktop Application
- Hardware: Any Windows PC with a USB or built-in webcam, minimum 4GB RAM, stable internet connection.
- Software: Windows 10/11, Python 3.10+, all packages from Requirements.txt.
- Network: Outbound access to HiveMQ Cloud (port 8883), Firebase (HTTPS), Cloudinary (HTTPS), and Google Gemini API (HTTPS).

### Mobile Application
- Android: Android 8.0 (API level 26) or higher, Google Play Services installed.
- iOS: iOS 13.0 or higher.

### Cloud Services Configuration

| Service | Configuration |
|---------|---------------|
| Firebase | Project home-security-f3878, Firestore in production mode, FCM enabled |
| HiveMQ Cloud | EU region cluster, TLS enabled, dedicated MQTT credentials |
| Cloudinary | Upload preset configured for image uploads |
| Gemini API | API key with Gemini 2.5 Flash model access |

## 8.3 Installation and Configuration

### Desktop Application Setup

1. Install Python 3.10 or higher from python.org.
2. Clone or copy the project to the target machine.
3. Install dependencies: pip install -r codes/Requirements.txt
4. Place the Firebase Admin SDK credentials file in the project root directory.
5. Verify config.py settings: set VIDEO_DEVICE_INDEX to the correct camera index (use scanner.py to discover available cameras) and TARGET_USER_ID to the Firebase UID of the household owner.
6. Run the application: python codes/main.py

### Mobile Application Setup

1. Install Flutter SDK 3.x and configure Android Studio or Xcode.
2. Clone the home_security Flutter project.
3. Run flutter pub get to install dependencies.
4. Ensure google-services.json (Android) is placed in android/app/.
5. Build and install: flutter build apk --release (Android) or flutter build ios --release (iOS).
6. Launch the app, register an account, and scan the desktop QR code to pair the camera.

## 8.4 Release Management

The project uses Git for version control with two main branches:
- main: Stable, tested releases.
- dev: Active development and feature integration.

Version numbers follow semantic versioning (MAJOR.MINOR.PATCH). The Flutter app version is defined in pubspec.yaml (version: 1.0.0+1).

## 8.5 Monitoring and Logging

### Desktop Application
- All significant events are logged to the GUI log area with timestamps.
- DEBUG and ERROR prefixed print statements provide console-level diagnostics.
- MQTT connection status and AI analysis results are logged in real time.

### Cloud Services
- Firebase Console provides real-time Firestore read/write monitoring and FCM delivery reports.
- HiveMQ Cloud dashboard shows MQTT connection counts and message throughput.
- Cloudinary dashboard tracks storage usage and bandwidth consumption.
- Google Cloud Console provides Gemini API usage metrics and quota monitoring.

## 8.6 Maintenance and Support Plan

- **Dependency updates:** Python packages and Flutter dependencies should be reviewed quarterly for security patches.
- **API key rotation:** Gemini API keys and MQTT credentials should be rotated every 6 months or immediately upon suspected compromise.
- **Firebase security rules:** Firestore security rules should be reviewed to ensure users can only access their own data.
- **Storage cleanup:** Old notification snapshots on Cloudinary and old video recordings on the local machine should be periodically purged to manage storage costs.
- **AI prompt tuning:** The Gemini analysis prompt can be updated to improve detection accuracy based on observed false positive/negative patterns without any code changes.

---

# Chapter 9: Conclusion and Future Work

## 9.1 Conclusions

This project successfully designed and implemented a comprehensive AI-powered home security system that addresses the key limitations of existing consumer surveillance solutions. The system integrates real-time encrypted video streaming, multimodal AI-based anomaly detection and facial recognition, cloud-based push notifications, and IoT hardware control into a unified platform accessible through a cross-platform mobile application.

The primary contributions of this project are:

1. **A novel zero-shot AI surveillance approach** using Google Gemini 2.5 Flash that eliminates the need for custom model training while supporting personalized family member recognition through reference photos.
2. **An end-to-end encrypted video streaming pipeline** using Fernet symmetric encryption over MQTT TLS, with a QR-code-based key exchange mechanism requiring no manual network configuration.
3. **A fully integrated IoT command-and-control architecture** using Firebase Firestore as a real-time message bus between the mobile application and physical hardware devices.
4. **A production-quality Flutter mobile application** providing live video monitoring, AI alert history with images, and remote hardware control in a Material Design 3 interface.

All research objectives stated in Chapter 1 were met. The system demonstrated reliable performance with sub-2-second stream latency, approximately 90% AI detection accuracy, and 2 to 4 second push notification delivery times.

## 9.2 Future Work

1. **Reduce AI analysis interval:** Investigate lighter local edge inference (e.g., TensorFlow Lite) to reduce the interval from 5 seconds to under 1 second.
2. **Multi-camera support:** Extend the desktop application to manage multiple cameras simultaneously with independent streaming and AI pipelines.
3. **On-device AI fallback:** Implement a lightweight local motion detection model as a fallback when the Gemini API is unavailable.
4. **Secure configuration management:** Replace hardcoded API keys in config.py with environment variables or a secrets management service.
5. **Mobile AI interval control:** Allow users to configure the AI analysis interval from the mobile app settings, writing configuration to Firestore.
6. **Video clip sharing:** Record a short clip around each anomaly event and upload to Cloudinary for richer notification context.
7. **Multi-user household support:** Support multiple family members sharing access with role-based permissions (admin vs. viewer).
8. **IoT hardware firmware:** Develop and document the ESP32/Arduino firmware that reads Firestore commands and controls physical actuators.
9. **Automated testing suite:** Implement comprehensive automated tests using pytest (desktop) and Flutter test framework (mobile) for CI/CD.
10. **Privacy mode:** Add a feature that pauses AI analysis and cloud uploads when family members are detected at home.

---

# References

[1] Eclipse Foundation, "MQTT Version 5.0 Specification," OASIS Standard, 2019. Available: https://mqtt.org/mqtt-specification/

[2] Google LLC, "Firebase Documentation," 2024. Available: https://firebase.google.com/docs

[3] Google LLC, "Gemini API Documentation," 2024. Available: https://ai.google.dev/docs

[4] HiveMQ GmbH, "HiveMQ Cloud Documentation," 2024. Available: https://www.hivemq.com/docs/hivemq-cloud/

[5] Cloudinary Ltd., "Cloudinary Documentation," 2024. Available: https://cloudinary.com/documentation

[6] Flutter Team, "Flutter Documentation," Google LLC, 2024. Available: https://docs.flutter.dev

[7] Python Software Foundation, "Python 3 Documentation," 2024. Available: https://docs.python.org/3/

[8] PyPA, "cryptography - Fernet symmetric encryption," 2024. Available: https://cryptography.io/en/latest/fernet/

[9] Bradski, G., "The OpenCV Library," Dr. Dobb's Journal of Software Tools, 2000.

[10] Alaba, F. A., Othman, M., Hashem, I. A. T., and Alotaibi, F., "Internet of Things Security: A Survey," Journal of Network and Computer Applications, vol. 88, pp. 10-28, 2017.

[11] Vaswani, A. et al., "Attention Is All You Need," in Advances in Neural Information Processing Systems, 2017.

[12] Google LLC, "Material Design 3 Guidelines," 2024. Available: https://m3.material.io/

[13] OASIS, "MQTT and the Internet of Things," White Paper, 2014.

---

# Appendix A

## A.1 Code Listings

### A.1.1 config.py - System Configuration

```python
import queue

VIDEO_DEVICE_INDEX = 1        # Camera device index
OUTPUT_FOLDER = "Videos"
CHUNK_DURATION = 300          # 5 minutes per recording chunk
CREDENTIALS_FILE = "device_credentials.json"

STREAM_WIDTH = 480
STREAM_HEIGHT = 320
STREAM_QUALITY = 50           # JPEG quality (0-100)
STREAM_INTERVAL = 0.15        # Minimum seconds between streamed frames

MQTT_BROKER = "<hivemq-cluster-url>"
MQTT_PORT = 8883
MQTT_USERNAME = "<mqtt-username>"
MQTT_PASSWORD = "<mqtt-password>"
TOPIC_VIDEO_BASE = "home/security/video"

GEMINI_API_KEY = "<gemini-api-key>"
AI_CHECK_INTERVAL = 5         # Seconds between AI analysis cycles

FIREBASE_CREDENTIALS_FILE = "<firebase-adminsdk>.json"
TARGET_USER_ID = "<firebase-user-uid>"

CLOUDINARY_CLOUD_NAME = "<cloud-name>"
CLOUDINARY_API_KEY = "<api-key>"
CLOUDINARY_API_SECRET = "<api-secret>"

video_stream_queue = queue.Queue(maxsize=1)
```

### A.1.2 crypto_manager.py - Device Identity and Encryption

```python
import os, json, uuid
from cryptography.fernet import Fernet
import config

class CryptoManager:
    def __init__(self):
        self.device_id = None
        self.key = None
        self.cipher = None
        self.load_or_generate_credentials()

    def load_or_generate_credentials(self):
        if os.path.exists(config.CREDENTIALS_FILE):
            with open(config.CREDENTIALS_FILE, 'r') as f:
                data = json.load(f)
                self.device_id = data.get("device_id")
                self.key = data.get("key").encode()
        else:
            self.generate_credentials()
        self.cipher = Fernet(self.key)

    def generate_credentials(self):
        self.device_id = str(uuid.uuid4())[:8]
        self.key = Fernet.generate_key()
        with open(config.CREDENTIALS_FILE, 'w') as f:
            json.dump({"device_id": self.device_id,
                       "key": self.key.decode()}, f, indent=4)

    def encrypt_message(self, message_bytes):
        return self.cipher.encrypt(message_bytes)

    def get_topic(self):
        return f"{config.TOPIC_VIDEO_BASE}/{self.device_id}"
```

## A.2 User Manuals

### A.2.1 Desktop Application - Quick Start Guide

1. Ensure Python 3.10+ is installed and all dependencies are installed via pip install -r Requirements.txt.
2. Place the Firebase credentials JSON file in the project root.
3. Run python codes/main.py from the project directory.
4. The application window opens showing the camera feed and a QR code on the right panel.
5. Click Start Recording to begin video capture, local recording, live streaming, and AI analysis simultaneously.
6. Open the mobile app and scan the QR code to pair the camera.
7. Click Stop Recording to stop all processes gracefully.

### A.2.2 Mobile Application - Quick Start Guide

1. Install the app on your Android or iOS device.
2. Register an account using your email and password, or sign in with Google.
3. On the Home screen, tap the camera settings icon and select Add Camera.
4. Scan the QR code displayed on the desktop application.
5. Select the camera from the dropdown to start viewing the live stream.
6. To add hardware: go to Settings, then Hardware, then Add Device and scan the hardware QR code.
7. Notifications will appear automatically when the AI detects anomalies.

## A.3 Performance Data

### A.3.1 Stream Latency Measurements

| Test Run | Stream Latency (s) | AI Response Time (s) | Notification Delivery (s) |
|----------|--------------------|----------------------|---------------------------|
| 1 | 0.9 | 3.2 | 2.8 |
| 2 | 1.1 | 4.1 | 3.5 |
| 3 | 0.8 | 2.9 | 2.1 |
| 4 | 1.4 | 5.3 | 4.2 |
| 5 | 1.2 | 3.8 | 3.1 |
| Average | 1.08 | 3.86 | 3.14 |

### A.3.2 AI Detection Accuracy

| Scenario | Frames Tested | Correct | Accuracy |
|----------|---------------|---------|----------|
| Empty room (no anomaly) | 20 | 18 | 90% |
| Known family member | 20 | 19 | 95% |
| Unknown intruder | 20 | 17 | 85% |
| Weapon visible | 10 | 9 | 90% |
| Overall | 70 | 63 | 90% |

---

*End of Document - AI-Powered Home Security System - Academic Year 2025-2026*
