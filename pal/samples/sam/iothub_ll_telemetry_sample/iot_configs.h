#ifndef IOT_CONFIGS_H
#define IOT_CONFIGS_H

#include <pins_arduino.h>
#include <SSLClient.h>


/**
 * IoT Hub Device Connection String setup
 * Find your Device Connection String by going to your Azure portal, creating (or navigating to) an IoT Hub, 
 * navigating to IoT Devices tab on the left, and creating (or selecting an existing) IoT Device. 
 * Then click on the named Device ID, and you will have able to copy the Primary or Secondary Device Connection String to this sample.
 */
#define DEVICE_CONNECTION_STRING    "your-iothub-DEVICE-connection-string"

// The protocol you wish to use should be uncommented
//
#define SAMPLE_MQTT
//#define SAMPLE_HTTP

// The following mac address will be assigned to the Ethernet Shield. 
// Please use the one written on the label on the bottom of the Shield.
static byte assigned_mac[] = {0x0A,0x0B,0x0C,0x0D,0x0E,0x0F};

// Analog Pin assigned to SSLClient library for generating random number. The pin must be floating and not used in your application.
#define RAND_PIN A11

#endif /* IOT_CONFIGS_H */
