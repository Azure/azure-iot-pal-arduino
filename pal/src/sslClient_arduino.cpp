// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#include <IPAddress.h>
#include "sslClient_arduino.h"
#include "azure_c_shared_utility/xlogging.h"

#ifdef ARDUINO_ARCH_ESP8266
#include "ESP8266WiFi.h"
#include "WiFiClientSecureBearSSL.h"
#include "certs/certs.h"
static BearSSL::WiFiClientSecure sslClient; // for ESP8266
static BearSSL::X509List cert(certificates);
#elif ARDUINO_ARCH_ESP32
#include "WiFi.h"
#include "WiFiClientSecure.h"
static WiFiClientSecure sslClient; // for ESP32
#elif ARDUINO_ARCH_SAM
#include <Dns.h>
#include <SSLClient.h>
#include <EthernetLarge.h>
#include <time_macros.h>
#include <time.h>
#include "sam/sample_init.h"

static EthernetClient baseClient;
SSLClient *p_sslClient;
#define sslClient (*p_sslClient)
#else
#include "WiFi101.h"
#include "WiFiSSLClient.h"
static WiFiSSLClient sslClient;
#endif

void sslClient_setTimeout(unsigned long timeout)
{
    sslClient.setTimeout(timeout);
}

uint8_t sslClient_connected(void)
{
    return (uint8_t)sslClient.connected();
}

int sslClient_connect(const char* name, uint16_t port)
{
#ifdef ARDUINO_ARCH_ESP8266
    sslClient.setTrustAnchors(&cert);
#endif
#ifdef ARDUINO_ARCH_SAM
    time_t current_time = time(NULL);
    //g_ variables declared as extern in sample_init
    p_sslClient = new SSLClient(baseClient, g_anchors, g_anchors_len, g_rand_pin);
    sslClient.setVerificationTime(// days since 1970 + days from 1970 to year 0 
 		(current_time / SEC_PER_DAY) + 719528UL, 
 		// seconds over start of day 
 		current_time % SEC_PER_DAY);
#endif
    return (int)sslClient.connect(name, port);
}

void sslClient_stop(void)
{
    sslClient.stop();
#ifdef ARDUINO_ARCH_SAM
    free(p_sslClient);
    p_sslClient = NULL;
#endif
}

size_t sslClient_write(const uint8_t *buf, size_t size)
{
    size_t ret;
#ifdef ARDUINO_ARCH_SAM
    // If there is data to read, stop write operation and continue
    if(sslClient.available()) 
        return 0;
#endif
    ret = sslClient.write(buf, size);
#ifdef ARDUINO_ARCH_SAM
    // Do not flush if there is pending data to read, flush will happens during available call.
    if(!sslClient.available()) {
        sslClient.flush();
    }
#endif
    return ret;
}

size_t sslClient_print(const char* str)
{
    return sslClient.print(str);
}

int sslClient_read(uint8_t *buf, size_t size)
{
#ifdef ARDUINO_ARCH_SAM
    int ret;
    int read_size = 0;
    // Read until there is data available or buffer is full
    do{
        ret = sslClient.read(&buf[read_size], size-read_size);
        read_size += ret;
    }while(sslClient.available() && read_size < size);
    return read_size;
#else
    return sslClient.read(buf, size);
#endif
}

int sslClient_available(void)
{
    return sslClient.available();
}

uint8_t sslClient_hostByName(const char* hostName, uint32_t* ipAddress)
{
    IPAddress ip;
    #ifdef ARDUINO_ARCH_SAM
    
    DNSClient dns;
    dns.begin(Ethernet.dnsServerIP());
    
    uint8_t result = dns.getHostByName(hostName,ip);
    (*ipAddress) = (uint32_t)ip;
    return result;
    #else
    
    uint8_t result = WiFi.hostByName(hostName, ip);
    (*ipAddress) = (uint32_t)ip;
    return result;

    #endif
   

}

