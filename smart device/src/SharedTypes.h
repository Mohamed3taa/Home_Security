#ifndef SHARED_TYPES_H
#define SHARED_TYPES_H

#include <Arduino.h>

struct DeviceState {
    float temperature;
    float humidity;
    bool isGateOpen;
    bool isAlarmOn;
    String statusMessage;
};

enum SystemCommand {
    CMD_NONE,
    CMD_OPEN_GATE,
    CMD_CLOSE_GATE,
    CMD_ALARM_ON,
    CMD_ALARM_OFF
};

enum BuzzerCommand {
    BUZZ_OFF,
    BUZZ_SHORT,
    BUZZ_ALARM_ON,
    BUZZ_ALARM_OFF
};

#endif