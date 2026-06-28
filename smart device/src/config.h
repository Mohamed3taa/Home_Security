#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// ==========================================
// HARDWARE SETTINGS
// ==========================================
// Existing Servo
#define SERVO1_PIN       4

// New Hardware
#define DHT_PIN          17 
#define DHT_TYPE         DHT22  
#define BUZZER_PIN       19  

// Servo Angles
#define GATE_OPEN_ANGLE     90
#define GATE_CLOSE_ANGLE    0

// ==========================================
// WIFI & FIREBASE SETTINGS
// ==========================================
#define WIFI_SSID       "YOUR_WIFI_SSID"
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"

#define API_KEY         "YOUR_FIREBASE_API_KEY"
#define USER_EMAIL      "YOUR_FIREBASE_USER_EMAIL"
#define USER_PASSWORD   "YOUR_FIREBASE_USER_PASSWORD"
#define PROJECT_ID      "YOUR_FIREBASE_PROJECT_ID"

// Firestore Paths
#define HARDWARE_COLLECTION_ID "Hardware"
#define DEVICE_DOC_ID          "Q66yzzufLIb0Ygwp9lbbrVHoV842"
#define STATES_SUBCOLLECTION   "states"
#define COMMANDS_SUBCOLLECTION "commands"

#define STATE_UPLOAD_INTERVAL  5000
#define COMMAND_POLL_INTERVAL  3000

// ==========================================
#define NTP_SERVER "pool.ntp.org"
#define NTP_OFFSET 7200
#define NTP_UPDATE 60000

#endif