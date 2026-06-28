#include "FirebaseLogic.h"
#include "../config.h"
#include "../SharedTypes.h"

#define ENABLE_USER_AUTH
#define ENABLE_FIRESTORE

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <WiFiUdp.h>
#include <NTPClient.h>
#include <FirebaseClient.h>

#define SSL_CLIENT WiFiClientSecure
static SSL_CLIENT ssl_client;
using AsyncClient = AsyncClientClass;
static AsyncClient aClient(ssl_client);

static UserAuth user_auth(API_KEY, USER_EMAIL, USER_PASSWORD, 3000);
static FirebaseApp app;
static Firestore::Documents Docs;

static WiFiUDP ntpUDP;
static NTPClient timeClient(ntpUDP, NTP_SERVER, NTP_OFFSET, NTP_UPDATE);

static QueueHandle_t _sensorQueue = NULL;
static QueueHandle_t _commandQueue = NULL;
extern bool globalGateState; 
extern bool globalAlarmState; 


String getISOTimestamp() {
    timeClient.update();
    unsigned long epoch = timeClient.getEpochTime();
    struct tm *ptm = gmtime((time_t *)&epoch);
    char buf[30];
    strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", ptm);
    return String(buf);
}

void printResult(AsyncResult &aResult) {
    if (aResult.isError()) {
        Serial.printf("[FB Error] %s\n", aResult.error().message().c_str());
    } else if (aResult.isEvent()) {
        Serial.printf("[FB Event] %s\n", aResult.eventLog().message().c_str());
    }
}

void deleteCommand(String docPath) {
    int docIndex = docPath.indexOf("/documents/");
    if (docIndex > -1) {
        String relativePath = docPath.substring(docIndex + 11); 
        Docs.deleteDoc(aClient, Firestore::Parent(PROJECT_ID), relativePath, Precondition(), printResult);
        Serial.println("Command processed and deleted.");
    }
}

void processCommandList(AsyncResult &aResult) {
    if (aResult.available()) {
        String json = aResult.c_str();

        if (json.indexOf("\"documents\":") > -1) {
            
            int nameIdx = json.indexOf("\"name\":");
            int nameEnd = json.indexOf("\"", nameIdx + 9);
            String docName = json.substring(nameIdx + 9, nameEnd); 

            SystemCommand cmdToSend = CMD_NONE;

            if (json.indexOf("SET_GATE") > -1) {
                if (json.indexOf("OPEN") > -1) cmdToSend = CMD_OPEN_GATE;
                else if (json.indexOf("CLOSE") > -1) cmdToSend = CMD_CLOSE_GATE;
            }
            else if (json.indexOf("SET_ALARM") > -1) {
                if (json.indexOf("ON") > -1) cmdToSend = CMD_ALARM_ON;
                else if (json.indexOf("OFF") > -1) cmdToSend = CMD_ALARM_OFF;
            }

            if (cmdToSend != CMD_NONE) {
                xQueueSend(_commandQueue, &cmdToSend, 0);
                deleteCommand(docName);
            } else {
                Serial.println("Unknown command found, deleting...");
                deleteCommand(docName);
            }
        }
    }
}

void pollCommands() {
    String path = String(HARDWARE_COLLECTION_ID) + "/" + DEVICE_DOC_ID + "/" + COMMANDS_SUBCOLLECTION;
    
    ListDocumentsOptions listOpts;
    listOpts.pageSize(1); 
    
    Docs.list(aClient, Firestore::Parent(PROJECT_ID), path, listOpts, processCommandList);
}

void uploadState(DeviceState envState) {
    String timestamp = getISOTimestamp();
    String path = String(HARDWARE_COLLECTION_ID) + "/" + DEVICE_DOC_ID + "/" + STATES_SUBCOLLECTION + "/" + timestamp;

    DocumentMask updateMask;
    DocumentMask responseMask;
    Precondition precondition;
    PatchDocumentOptions patchOpts(updateMask, responseMask, precondition);

    Document<Values::Value> doc;
    doc.add("temperature", Values::Value(Values::DoubleValue(envState.temperature)));
    doc.add("humidity", Values::Value(Values::DoubleValue(envState.humidity)));
    
    doc.add("gate", Values::Value(Values::BooleanValue(globalGateState)));
    doc.add("alarm_state", Values::Value(Values::BooleanValue(globalAlarmState)));
    
    doc.add("state", Values::Value(Values::StringValue("Online")));
    doc.add("timestamp", Values::Value(Values::StringValue(timestamp)));

    Docs.patch(aClient, Firestore::Parent(PROJECT_ID), path, patchOpts, doc, printResult);
    Serial.println("State Uploaded: " + timestamp);
}

void TaskFirebase(void *pvParameters) {
    Serial.print("Connecting to WiFi");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        vTaskDelay(pdMS_TO_TICKS(500));
    }
    Serial.println("\nWiFi Connected!");

    ssl_client.setInsecure();
    initializeApp(aClient, app, getAuth(user_auth), printResult, "authTask");
    app.getApp<Firestore::Documents>(Docs);
    timeClient.begin();

    unsigned long lastPushTime = 0;
    unsigned long lastPollTime = 0;
    DeviceState localState;

    for (;;) {
        app.loop();

        if (app.ready()) {
            unsigned long now = millis();

            if (now - lastPushTime > STATE_UPLOAD_INTERVAL) {
                if (xQueuePeek(_sensorQueue, &localState, 0) == pdPASS) {
                    uploadState(localState);
                    lastPushTime = now;
                }
            }

            if (now - lastPollTime > COMMAND_POLL_INTERVAL) {
                pollCommands();
                lastPollTime = now;
            }
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

void startFirebaseTask(void *queues) {
    QueueHandle_t *q = (QueueHandle_t *)queues;
    _sensorQueue = q[0];
    _commandQueue = q[1];
    
    xTaskCreate(TaskFirebase, "FirebaseTask", 12000, NULL, 1, NULL);
}