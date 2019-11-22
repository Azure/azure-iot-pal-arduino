// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#ifdef ARDUINO_ARCH_ESP32

#include <Arduino.h>
#include <time.h>
#include "AzureIoTSocket_WiFi.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <WiFiUdp.h>

// Times before 2010 (1970 + 40 years) are invalid
#define MIN_EPOCH 40 * 365 * 24 * 3600


static void initSerial() {
    // Start serial and initialize stdout
    Serial.begin(1000000);
    Serial.setDebugOutput(true);
}

static void initWifi(const char* ssid, const char* pass) {
    // Attempt to connect to Wifi network:
    Serial.print("\r\n\r\nAttempting to connect to SSID: ");
    Serial.println(ssid);
    
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    WiFi.begin(ssid, pass);
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
    }
    
    Serial.println("\r\nConnected to wifi");
}


void esp32_sample_init(const char* ssid, const char* password)
{
    initSerial();
    initWifi(ssid, password);
    initTime();
}

#endif // ARDUINO_ARCH_ESP32
