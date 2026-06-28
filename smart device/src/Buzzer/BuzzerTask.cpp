#include "BuzzerTask.h"
#include "../config.h"
#include "../SharedTypes.h"

// Changed to Channel 8 to avoid conflict with Servo library (which uses Channels 0-1)
#define BUZZER_CHANNEL 8
#define BUZZER_FREQ 2000
#define BUZZER_RES 8

void TaskBuzzer(void *pvParameters) {
    QueueHandle_t buzzerQueue = (QueueHandle_t)pvParameters;

    ledcSetup(BUZZER_CHANNEL, BUZZER_FREQ, BUZZER_RES);
    ledcAttachPin(BUZZER_PIN, BUZZER_CHANNEL);
    ledcWrite(BUZZER_CHANNEL, 0);

    BuzzerCommand currentMode = BUZZ_OFF;
    BuzzerCommand incomingCmd;

    for (;;) {
        if (xQueueReceive(buzzerQueue, &incomingCmd, 0) == pdPASS) {
            currentMode = incomingCmd;
        }

        switch (currentMode) {
            case BUZZ_SHORT:
                ledcWriteTone(BUZZER_CHANNEL, 1500);
                vTaskDelay(pdMS_TO_TICKS(150));
                ledcWrite(BUZZER_CHANNEL, 0);
                currentMode = BUZZ_OFF; 
                break;

            case BUZZ_ALARM_ON:
                ledcWriteTone(BUZZER_CHANNEL, 2500);
                vTaskDelay(pdMS_TO_TICKS(300));
                ledcWriteTone(BUZZER_CHANNEL, 2000);
                vTaskDelay(pdMS_TO_TICKS(300));
                break;

            case BUZZ_ALARM_OFF:
            case BUZZ_OFF:
            default:
                ledcWrite(BUZZER_CHANNEL, 0);
                vTaskDelay(pdMS_TO_TICKS(100));
                break;
        }
    }
}