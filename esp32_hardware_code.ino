#include <Wire.h>
#include "Adafruit_VL53L0X.h"
#include <Adafruit_NeoPixel.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// BLE Libraries
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_bt.h"

#define LED_PIN 5
#define NUM_LEDS 8
#define BUZZER_PIN 18

Adafruit_VL53L0X lox;
Adafruit_NeoPixel strip(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);
Adafruit_MPU6050 mpu;

// BLE Variables
BLEServer* pServer = NULL;
BLECharacteristic* pNotifyCharacteristic = NULL;
BLECharacteristic* pWriteCharacteristic = NULL;
bool deviceConnected = false;

// UUIDs
#define SERVICE_UUID     "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define NOTIFY_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WRITE_CHAR_UUID  "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// Exercise variables
String currentExercise = "";
int repCount = 0;
bool movementStarted = false;
String lastSentStatus = "";

// 🔥 Threshold struct (from old code)
struct ExerciseThresholds {
  int wrongMax;
  int nearMin;
  int correctMin;
};

ExerciseThresholds getThresholds(String exercise) {
  ExerciseThresholds t;

  if (exercise == "leg_raise") {
    t.wrongMax = 150;
    t.nearMin = 150;
    t.correctMin = 300;
  }
  else if (exercise == "knee_extension") {
    t.wrongMax = 100;
    t.nearMin = 100;
    t.correctMin = 250;
  }
  else if (exercise == "wall_squat") {
    t.wrongMax = 200;
    t.nearMin = 200;
    t.correctMin = 350;
  }
  else {
    t.wrongMax = 150;
    t.nearMin = 150;
    t.correctMin = 300;
  }

  return t;
}

// LED
void setColor(int r, int g, int b) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, strip.Color(r, g, b));
  }
  strip.show();
}

// 🔥 BUZZER (from old code)
void beepCorrect() {
  tone(BUZZER_PIN, 1000, 150);
}

void beepWrong() {
  tone(BUZZER_PIN, 500, 200);
  delay(200);
  tone(BUZZER_PIN, 500, 200);
}

// BLE Callbacks
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) { 
    deviceConnected = true; 
    Serial.println("Device Connected ✅");
  }

  void onDisconnect(BLEServer* pServer) { 
    deviceConnected = false; 
    BLEDevice::startAdvertising();
    Serial.println("Re-advertising...");
  }
};

class ExerciseWriteCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    value.trim(); value.toLowerCase();

    // 🔥 MULTI EXERCISE (from old code)
    if (value == "leg_raise" || value == "knee_extension" || value == "wall_squat") {
      currentExercise = value;
      repCount = 0;
      movementStarted = false;
      Serial.println("Exercise: " + value);
    }
    else if (value == "stop") {
      currentExercise = "";
      setColor(0,0,0);
    }
  }
};

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  pinMode(BUZZER_PIN, OUTPUT);

  strip.begin();
  strip.show();

  Serial.println("Initializing Sensors...");

  // MPU
  mpu.begin();
  Wire.beginTransmission(0x68);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);

  Serial.println("MPU Ready ✅");

  // ToF
  if (!lox.begin()) {
    Serial.println("VL53L0X NOT FOUND ❌");
    while (1);
  }
  Serial.println("VL53L0X OK ✅");

  // BLE FIX
  esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT);

  BLEDevice::init("ESP32_Reflexa");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pNotifyCharacteristic = pService->createCharacteristic(
    NOTIFY_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pNotifyCharacteristic->addDescriptor(new BLE2902());

  pWriteCharacteristic = pService->createCharacteristic(
    WRITE_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pWriteCharacteristic->setCallbacks(new ExerciseWriteCallback());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();

  Serial.println("BLE Advertising Started ✅");
  Serial.println("System Ready ✅");
}

void loop() {

  if (currentExercise == "" || !deviceConnected) {
    delay(100);
    return;
  }

  // ToF
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false);
  if (measure.RangeStatus == 4) return;

  int distance = measure.RangeMilliMeter;

  // MPU
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  float angle = atan2(a.acceleration.x, a.acceleration.z) * 180 / PI;

  // 🔥 USE THRESHOLDS
  ExerciseThresholds t = getThresholds(currentExercise);
  String status = "";

  if (distance < t.wrongMax || angle < 20) {
    setColor(255,0,0);
    beepWrong();
    status = "wrong";
    movementStarted = true;
  }
  else if (distance >= t.nearMin && distance < t.correctMin && angle >= 20 && angle < 40) {
    setColor(255,150,0);
    status = "near";
  }
  else if (distance >= t.correctMin && angle >= 40) {
    setColor(0,255,0);
    status = "correct";

    if (movementStarted) {
      repCount++;
      movementStarted = false;
      beepCorrect();

      String msg = "rep:" + String(repCount);
      pNotifyCharacteristic->setValue(msg.c_str());
      pNotifyCharacteristic->notify();
    }
  }

  if (status != lastSentStatus) {
    pNotifyCharacteristic->setValue(status.c_str());
    pNotifyCharacteristic->notify();
    lastSentStatus = status;
  }

  Serial.print("Dist: ");
  Serial.print(distance);
  Serial.print(" | Angle: ");
  Serial.print(angle);
  Serial.print(" | Reps: ");
  Serial.println(repCount);

  delay(200);
}