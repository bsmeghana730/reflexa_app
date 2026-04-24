/*
 * REFLEXA SLAVE SENSOR
 * Monitors LDR for Pickup
 * Measures distance via TOF (VL53L0X)
 * Sends data via ESP-NOW to Master
 */

#include <esp_now.h>
#include <WiFi.h>
#include "Adafruit_VL53L0X.h"

// --- CONFIGURATION ---
#define MY_DEVICE_ID 1       // IMPORTANT: Change this to 1, 2, 3, 4, 5, 6 for each sensor
#define LDR_PIN 34           // Analog Pin for LDR
#define THRESHOLD 2000       // Light threshold for pickup detection

// YOUR MASTER MAC ADDRESS
uint8_t masterMac[] = {0x28, 0x05, 0xA5, 0x30, 0x40, 0x60}; 

Adafruit_VL53L0X lox = Adafruit_VL53L0X();

typedef struct struct_message {
    int deviceID;
    char command[32];
    float distanceValue;
} struct_message;

struct_message outgoingData;
bool isPickedUp = false;

void sendToMaster(const char* cmd, float val) {
    outgoingData.deviceID = MY_DEVICE_ID;
    strcpy(outgoingData.command, cmd);
    outgoingData.distanceValue = val;
    esp_now_send(masterMac, (uint8_t *) &outgoingData, sizeof(outgoingData));
}

void setup() {
    Serial.begin(115200);

    // 1. Initialize TOF
    if (!lox.begin()) {
        Serial.println("Failed to find VL53L0X sensor");
        while (1);
    }

    // 2. WiFi & ESP-NOW
    WiFi.mode(WIFI_STA);
    if (esp_now_init() != ESP_OK) {
        Serial.println("Error initializing ESP-NOW");
        return;
    }

    // Register Master as Peer
    esp_now_peer_info_t peerInfo;
    memcpy(peerInfo.peer_addr, masterMac, 6);
    peerInfo.channel = 0;  
    peerInfo.encrypt = false;
    if (esp_now_add_peer(&peerInfo) != ESP_OK){
        Serial.println("Failed to add peer (Master)");
        return;
    }
}

void loop() {
    int light = analogRead(LDR_PIN);

    if (light > THRESHOLD) {
        if (!isPickedUp) {
            isPickedUp = true;
            sendToMaster("PICKED_UP", 0);
            Serial.println("Sensor Picked Up");
        }

        // Measure Distance
        VL53L0X_RangingMeasurementData_t measure;
        lox.rangingTest(&measure, false);

        if (measure.RangeStatus != 4) {
            float dist = measure.RangeMilliMeter;
            sendToMaster("DATA", dist);
            Serial.printf("Dist: %.1f mm\n", dist);
        }
    } 
    else {
        if (isPickedUp) {
            isPickedUp = false;
            sendToMaster("RETURNED", 0);
            Serial.println("Sensor Docked");
        }
    }

    delay(50); // 20Hz update frequency
}
