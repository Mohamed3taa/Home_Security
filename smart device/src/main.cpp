#include <Arduino.h>
#include "config.h"
#include "SharedTypes.h"
#include "Sensor/SensorTasks.h"
#include "Gate/GateTask.h"
#include "Buzzer/BuzzerTask.h"
#include "Firebase/FirebaseLogic.h"

QueueHandle_t sensorQueue;   
QueueHandle_t commandQueue;  
QueueHandle_t buzzerQueue;   

void setup() {
    Serial.begin(115200);
    
    sensorQueue = xQueueCreate(1, sizeof(DeviceState));
    commandQueue = xQueueCreate(5, sizeof(SystemCommand));
    buzzerQueue = xQueueCreate(5, sizeof(BuzzerCommand));

    if (!sensorQueue || !commandQueue || !buzzerQueue) {
        Serial.println("Error creating queues");
        while(1);
    }

    xTaskCreate(TaskSensorMonitor, "SensorTask", 4096, (void*)sensorQueue, 1, NULL);

    // Pass Buzzer Queue to Buzzer Task
    xTaskCreate(TaskBuzzer, "BuzzerTask", 2048, (void*)buzzerQueue, 1, NULL);

    // Pass BOTH CommandQueue and BuzzerQueue to GateTask
    static QueueHandle_t gateTaskQueues[2];
    gateTaskQueues[0] = commandQueue;
    gateTaskQueues[1] = buzzerQueue;
    xTaskCreate(TaskGateControl, "GateTask", 4096, (void*)gateTaskQueues, 1, NULL);

    QueueHandle_t fbQueues[2] = {sensorQueue, commandQueue};
    startFirebaseTask(fbQueues);

    Serial.println("System Started: Smart Gate + DHT + Buzzer + Firebase");
}

void loop() {
    vTaskDelete(NULL);
}