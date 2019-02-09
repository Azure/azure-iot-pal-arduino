// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#ifndef AZUREIOTSOCKETWIFI_H
#define AZUREIOTSOCKETWIFI_H

#define AzureIoTSocketWiFiVersion "1.0.00"

#ifdef ARDUINO_ARCH_ESP8266
#include <ESP8266WiFi.h>
#elif ARDUINO_ARCH_ESP32
#include <WiFi.h>
#else
#include <WiFi101.h>
#endif

// Helper function

void initTime() 
{  
  const int MIN_EPOCH = 40 * 365 * 24 * 3600;
  time_t epochTime;

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");

  Serial.print("Fetching time from NTP");
  
  epochTime = time(NULL);
  
  while (epochTime < MIN_EPOCH)
  {
    Serial.print(".");
    delay(2000);
    epochTime = time(NULL);
  }

  Serial.println();
  Serial.print("Fetched NTP epoch time is: ");
  Serial.println(epochTime);
}

#endif //AZUREIOTSOCKETWIFI_H
