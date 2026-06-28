#include "GateTask.h"
#include "../config.h"
#include "../SharedTypes.h"
#include <ESP32Servo.h>

extern bool globalGateState; 
extern bool globalAlarmState;

bool globalGateState = false;
bool globalAlarmState = false;

void TaskGateControl(void *pvParameters) {
    QueueHandle_t *queues = (QueueHandle_t *)pvParameters;
    QueueHandle_t commandQueue = queues[0];
    QueueHandle_t buzzerQueue = queues[1];

    Servo gateServo1;
    gateServo1.attach(SERVO1_PIN);
    gateServo1.write(GATE_CLOSE_ANGLE);

    SystemCommand cmd;
    BuzzerCommand buzzCmd;

    for (;;) {
        if (xQueueReceive(commandQueue, &cmd, portMAX_DELAY) == pdPASS) {
            Serial.printf("Executing Command: %d\n", cmd);

            switch (cmd) {
                case CMD_OPEN_GATE:
                    Serial.println(">>> OPENING GATE");
                    gateServo1.write(GATE_OPEN_ANGLE);
                    globalGateState = true;
                    buzzCmd = BUZZ_SHORT;
                    xQueueSend(buzzerQueue, &buzzCmd, 0);
                    break;

                case CMD_CLOSE_GATE:
                    Serial.println(">>> CLOSING GATE");
                    gateServo1.write(GATE_CLOSE_ANGLE);
                    globalGateState = false;
                    break;

                case CMD_ALARM_ON:
                    Serial.println(">>> ALARM ON");
                    globalAlarmState = true;
                    buzzCmd = BUZZ_ALARM_ON;
                    xQueueSend(buzzerQueue, &buzzCmd, 0);
                    break;

                case CMD_ALARM_OFF:
                    Serial.println(">>> ALARM OFF");
                    globalAlarmState = false;
                    buzzCmd = BUZZ_ALARM_OFF;
                    xQueueSend(buzzerQueue, &buzzCmd, 0);
                    break;
                
                default:
                    break;
            }
        }
    }
}