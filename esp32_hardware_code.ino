#include <Wire.h>
#include "Adafruit_VL53L0X.h"
#include <Adafruit_NeoPixel.h>

// BLE Libraries
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define LED_PIN 18      // Fixed: was 5 (strapping pin)
#define NUM_LEDS 8

Adafruit_VL53L0X lox = Adafruit_VL53L0X();
Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);

// BLE Variables
BLEServer* pServer = NULL;
BLECharacteristic* pNotifyCharacteristic = NULL;
BLECharacteristic* pWriteCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool ackSent = false;

// UUIDs
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define NOTIFY_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WRITE_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// Exercise variables
String currentExercise = "";
int repCount = 0;
int targetReps = 10;
bool movementStarted = false;
String lastSentStatus = "";

// Exercise-specific thresholds
struct ExerciseThresholds {
  int wrongMax;
  int nearMin;
  int correctMin;
};

ExerciseThresholds getThresholds(String exercise) {
  ExerciseThresholds t;
  if (exercise == "leg_raise") {
    t.wrongMax = 150; t.nearMin = 150; t.correctMin = 300;
  } else if (exercise == "knee_extension") {
    t.wrongMax = 100; t.nearMin = 100; t.correctMin = 250;
  } else if (exercise == "wall_squat") {
    t.wrongMax = 200; t.nearMin = 200; t.correctMin = 350;
  } else {
    t.wrongMax = 150; t.nearMin = 150; t.correctMin = 300;
  }
  return t;
}

// LED functions
void setColor(int r, int g, int b) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, strip.Color(r, g, b));
  }
  strip.show();
}

void blinkRed() {
  for (int i = 0; i < 3; i++) {
    setColor(255, 0, 0);
    delay(150);
    setColor(0, 0, 0);
    delay(150);
  }
}

void showCompletionEffect() {
  for (int i = 0; i < 5; i++) {
    setColor(0, 255, 0);
    delay(300);
    setColor(0, 0, 0);
    delay(300);
  }
}

// BLE Callbacks
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Bluetooth Client Connected!");
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Bluetooth Client Disconnected!");
  }
};

class ExerciseWriteCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    if (value.length() > 0) {
      value.trim();
      value.toLowerCase();

      if (value == "leg_raise" || value == "legraise") {
        currentExercise = "leg_raise";
        repCount = 0; movementStarted = false;
        Serial.println("========================================");
        Serial.println("Exercise Selected: LEG RAISE");
        Serial.println("Position: Lying on back, raise leg up");
        Serial.println("Thresholds: <150mm=Wrong, 150-300mm=Near, >300mm=Correct");
        Serial.println("========================================");
      } else if (value == "knee_extension" || value == "kneeextension") {
        currentExercise = "knee_extension";
        repCount = 0; movementStarted = false;
        Serial.println("========================================");
        Serial.println("Exercise Selected: KNEE EXTENSION");
        Serial.println("Position: Seated, extend knee outward");
        Serial.println("Thresholds: <100mm=Wrong, 100-250mm=Near, >250mm=Correct");
        Serial.println("========================================");
      } else if (value == "wall_squat" || value == "wallsquat" || value == "wall_support_squat") {
        currentExercise = "wall_squat";
        repCount = 0; movementStarted = false;
        Serial.println("========================================");
        Serial.println("Exercise Selected: WALL SUPPORT SQUAT");
        Serial.println("Position: Back against wall, squat down");
        Serial.println("Thresholds: <200mm=Wrong, 200-350mm=Near, >350mm=Correct");
        Serial.println("========================================");
      } else if (value == "stop" || value == "end") {
        currentExercise = "";
        repCount = 0;
        setColor(0, 0, 0);
        Serial.println("Exercise stopped by user");
      } else if (value == "reset") {
        repCount = 0; movementStarted = false;
        Serial.println("Rep count reset to 0");
      } else {
        Serial.print("Unknown command received: ");
        Serial.println(value);
      }
    }
  }
};

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  // Initialize LED strip
  strip.begin();
  strip.setBrightness(100);
  strip.show();

  // Startup LED test — confirms strip is alive
  Serial.println("Running LED startup test...");
  setColor(255, 0, 0); delay(500);  // Red
  setColor(0, 255, 0); delay(500);  // Green
  setColor(0, 0, 255); delay(500);  // Blue
  setColor(0, 0, 0);                // Off
  Serial.println("LED startup test done.");

  // Initialize VL53L0X sensor
  if (!lox.begin()) {
    Serial.println("VL53L0X not detected! Check wiring.");
    while (1) {
      blinkRed();
      delay(1000);
    }
  }
  Serial.println("VL53L0X initialized successfully");

  // BLE Setup
  Serial.println("Initializing BLE...");
  BLEDevice::init("ESP32_Reflexa");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pNotifyCharacteristic = pService->createCharacteristic(
    NOTIFY_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pNotifyCharacteristic->addDescriptor(new BLE2902());

  pWriteCharacteristic = pService->createCharacteristic(
    WRITE_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  pWriteCharacteristic->setCallbacks(new ExerciseWriteCallback());

  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("========================================");
  Serial.println("ESP32 Reflexa Ready!");
  Serial.println("Waiting for app connection...");
  Serial.println("========================================");
}

void loop() {
  // Handle BLE disconnection and re-advertising
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Restarting Bluetooth Advertising...");
    oldDeviceConnected = deviceConnected;
    ackSent = false;
    currentExercise = "";
    repCount = 0;
    setColor(0, 0, 0);
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Send ACK after connection
  if (deviceConnected && !ackSent) {
    static unsigned long lastAckAttempt = 0;
    static int ackAttempts = 0;
    if (millis() - lastAckAttempt > 1000) {
      lastAckAttempt = millis();
      pNotifyCharacteristic->setValue("ack");
      pNotifyCharacteristic->notify();
      Serial.println("Sent ACK to app");
      ackAttempts++;
      if (ackAttempts > 5) {
        ackSent = true;
        ackAttempts = 0;
        Serial.println("Handshake complete. Waiting for exercise selection...");
      }
    }
  }

  if (currentExercise == "" || !deviceConnected) {
    delay(100);
    return;
  }

  // Read distance from sensor
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false);

  if (measure.RangeStatus != 4) {
    int distance = measure.RangeMilliMeter;
    ExerciseThresholds thresholds = getThresholds(currentExercise);
    String currentStatus = "";

    if (distance < thresholds.wrongMax) {
      blinkRed();
      currentStatus = "wrong";
      movementStarted = true;
      Serial.print("["); Serial.print(currentExercise);
      Serial.print("] WRONG - Distance: "); Serial.print(distance); Serial.println("mm");

    } else if (distance >= thresholds.nearMin && distance < thresholds.correctMin) {
      setColor(255, 150, 0);
      currentStatus = "near";
      Serial.print("["); Serial.print(currentExercise);
      Serial.print("] ALMOST - Distance: "); Serial.print(distance); Serial.println("mm");

    } else if (distance >= thresholds.correctMin) {
      setColor(0, 255, 0);
      currentStatus = "correct";
      if (movementStarted) {
        repCount++;
        movementStarted = false;
        Serial.print("["); Serial.print(currentExercise);
        Serial.print("] CORRECT - Rep #"); Serial.print(repCount);
        Serial.print(" - Distance: "); Serial.print(distance); Serial.println("mm");
        Serial.println("----------------");
        String repMsg = "rep:" + String(repCount);
        pNotifyCharacteristic->setValue(repMsg.c_str());
        pNotifyCharacteristic->notify();
      }
    }

    if (deviceConnected && currentStatus != lastSentStatus && currentStatus != "") {
      pNotifyCharacteristic->setValue(currentStatus.c_str());
      pNotifyCharacteristic->notify();
      lastSentStatus = currentStatus;
    }

    if (repCount >= targetReps) {
      Serial.println("========================================");
      Serial.println("EXERCISE COMPLETED!");
      Serial.print("Total Reps: "); Serial.println(repCount);
      Serial.println("========================================");
      pNotifyCharacteristic->setValue("complete");
      pNotifyCharacteristic->notify();
      showCompletionEffect();
      delay(3000);
      repCount = 0;
      movementStarted = false;
      currentExercise = "";
      lastSentStatus = "";
    }

  } else {
    setColor(50, 50, 50);  // Dim white — sensor out of range
  }

  delay(200);
}
