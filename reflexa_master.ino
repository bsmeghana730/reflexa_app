/*
 * REFLEXA MASTER GATEWAY
 * Connects to Phone via BLE
 * Connects to 6 Slaves via ESP-NOW
 */

#include <esp_now.h>
#include <WiFi.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE UUIDs (Matching your existing app)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define NOTIFY_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WRITE_CHARACTERISTIC_UUID  "beb5483e-36e1-4688-b7f5-ea07361b26a9"

BLEServer* pServer = NULL;
BLECharacteristic* pNotifyCharacteristic = NULL;
bool deviceConnected = false;

// Data Structure (Must match Slave)
typedef struct struct_message {
    int deviceID;
    char command[32];
    float distanceValue;
} struct_message;

struct_message incomingData;
bool activeDevices[7] = {false}; // Tracking which of the 1-6 devices are out of dock

// --- ESP-NOW CALLBACK ---
void OnDataRecv(const esp_now_recv_info_t *recv_info, const uint8_t *incomingDataRaw, int len) {
    memcpy(&incomingData, incomingDataRaw, sizeof(incomingData));
    int id = incomingData.deviceID;

    if (strcmp(incomingData.command, "PICKED_UP") == 0) {
        activeDevices[id] = true;
        sendActiveListToPhone();
    } 
    else if (strcmp(incomingData.command, "RETURNED") == 0) {
        activeDevices[id] = false;
        sendActiveListToPhone();
    }
    else if (strcmp(incomingData.command, "DATA") == 0) {
        // Forward TOF distance data to phone: "D:ID:VALUE"
        String dataMsg = "D:" + String(id) + ":" + String(incomingData.distanceValue);
        if (deviceConnected) {
            pNotifyCharacteristic->setValue(dataMsg.c_str());
            pNotifyCharacteristic->notify();
        }
    }
}

void sendActiveListToPhone() {
    String list = "ACTIVE_LIST:";
    for (int i = 1; i <= 6; i++) {
        if (activeDevices[i]) list += String(i) + ",";
    }
    if (deviceConnected) {
        pNotifyCharacteristic->setValue(list.c_str());
        pNotifyCharacteristic->notify();
    }
    Serial.println("Sent to Phone: " + list);
}

// --- BLE CALLBACKS ---
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Phone Connected");
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Phone Disconnected");
      pServer->getAdvertising()->start();
    }
};

void setup() {
    Serial.begin(115200);

    // 1. WiFi & ESP-NOW
    WiFi.mode(WIFI_STA);
    if (esp_now_init() != ESP_OK) {
        Serial.println("Error initializing ESP-NOW");
        return;
    }
    esp_now_register_recv_cb(OnDataRecv);

    // 2. BLE Setup
    BLEDevice::init("Reflexa_Master");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);
    pNotifyCharacteristic = pService->createCharacteristic(
                      NOTIFY_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
    pNotifyCharacteristic->addDescriptor(new BLE2902());

    BLECharacteristic *pWriteCharacteristic = pService->createCharacteristic(
                                          WRITE_CHARACTERISTIC_UUID,
                                          BLECharacteristic::PROPERTY_WRITE
                                        );

    pService->start();
    pServer->getAdvertising()->start();
    Serial.println("Master Gateway Ready");
}

void loop() {
    // Master stays idle, mostly responding to interrupts and callbacks
    delay(1000);
}
