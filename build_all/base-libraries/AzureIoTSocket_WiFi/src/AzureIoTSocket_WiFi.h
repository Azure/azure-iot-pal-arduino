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

#endif //AZUREIOTSOCKETWIFI_H
