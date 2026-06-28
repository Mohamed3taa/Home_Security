#include "SensorTasks.h"
#include "../config.h"
#include "../SharedTypes.h"
#include <DHT.h>

DHT dht(DHT_PIN, DHT_TYPE);

void TaskSensorMonitor(void *pvParameters) {
    QueueHandle_t sensorQueue = (QueueHandle_t)pvParameters;

    dht.begin();
    pinMode(DHT_PIN, INPUT);

    DeviceState currentState;
    currentState.isGateOpen = false;
    currentState.isAlarmOn = false; 
    currentState.statusMessage = "Online";

    for (;;) {
        float h = dht.readHumidity();
        float t = dht.readTemperature();

        if (isnan(h) || isnan(t)) {
            Serial.println(F("Failed to read from DHT sensor!"));
            currentState.temperature = -1;
            currentState.humidity = -1;
        } else {
            currentState.temperature = t;
            currentState.humidity = h;
        }
        xQueueOverwrite(sensorQueue, &currentState);
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}