// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#ifdef ARDUINO_ARCH_SAM

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>

#include <EthernetLarge.h>
#include <EthernetUdp.h>
#include "NTPClientAz.h"

#include <SSLClient.h>
#include <EthernetLarge.h>

#include "certs/certs.h"
#include "pem_to_ta.h"


br_x509_trust_anchor *g_anchors = NULL;
size_t g_anchors_len = 0;
int g_rand_pin = A11;


static void initEthernet(byte *mac)
{
    bool not_connected = true;
    // start the Ethernet connection:
    Serial.println("Initialize Ethernet with DHCP:");
    do
    {
        if (Ethernet.begin(mac) == 0)
        {
            Serial.println("Failed to configure Ethernet using DHCP");
            // Check for Ethernet hardware present
            if (Ethernet.hardwareStatus() == EthernetNoHardware)
            {
                Serial.println("Ethernet shield was not found.  Sorry, can't run without hardware. :(");
                while (true)
                {
                    delay(1); // do nothing, no point running without Ethernet hardware
                }
            }
            if (Ethernet.linkStatus() == LinkOFF)
            {
                Serial.println("Ethernet cable is not connected.");
            }
            // try to configure using IP address instead of DHCP:
            // Ethernet.begin(mac, ip, myDns);
            delay(500);
        }
        else
        {
            not_connected = false;
        }
    }while(not_connected);

    Serial.print("  DHCP assigned IP ");
    Serial.println(Ethernet.localIP());
    
    // give the Ethernet shield a second to initialize:
    delay(1000);
}

static void initTime()
{
    EthernetUDP _udp;

    time_t epochTime = (time_t)-1;

    NTPClientAz ntpClient;
    Serial.println("Fetching NTP epoch time");
    ntpClient.begin();

    while (true)
    {
        epochTime = ntpClient.getEpochTime("0.pool.ntp.org");

        if (epochTime == (time_t)-1)
        {
            Serial.println("Fetching NTP epoch time failed! Waiting 2 seconds to retry.");
            delay(2000);
        }
        else
        {
            Serial.print("Fetched NTP epoch time is: ");
            Serial.println((uint32_t)epochTime);
            break;
        }
    }

    ntpClient.end();

    struct timeval tv;
    tv.tv_sec = epochTime;
    tv.tv_usec = 0;

    settimeofday(&tv, NULL);
    
} 

void due_sample_init(byte *mac, 
                    const int rand_pin)
{


    Serial.begin(115200);
    initEthernet(mac);
    initTime();

    // Certificate conversion
    pem_to_ta(certificates, strlen(certificates), &g_anchors, &g_anchors_len);
    g_rand_pin = rand_pin;
    //p_sslClient = new SSLClient(baseClient, anchors, anchors_len, rand_pin);
    delay(1000);
}

#endif // ARDUINO_ARCH_SAM
