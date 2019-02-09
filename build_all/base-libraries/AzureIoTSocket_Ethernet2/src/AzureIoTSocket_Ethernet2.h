// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#ifndef AZUREIOTSOCKETETHERNET2_H
#define AZUREIOTSOCKETETHERNET2_H

#define AzureIoTSocketWiFiVersion "1.0.00"

#ifdef ARDUINO_ARCH_ESP8266
#define ETHERNET2_PIN 15
#elif ARDUINO_ARCH_ESP32
#define ETHERNET2_PIN 33
#else
#define ETHERNET2_PIN "Unknown"
#endif

#include <Ethernet2.h>
#include <EthernetUdp2.h>
#include <sys/time.h>
#include <time.h>

#define NTP_PACKET_SIZE 48
#define LOCAL_PORT 8888
#define TIME_SERVER "time.nist.gov"

EthernetUDP udp;

static bool getNTPResponse()
{
  // wait to see if a reply is available
  bool result = (0 != udp.parsePacket());
  struct timeval tp = {0, 0};
  byte packetBuffer[NTP_PACKET_SIZE];
  
  if (result) 
  {
    // We've received a packet, read the data from it
    udp.read(packetBuffer, NTP_PACKET_SIZE); // read the packet into the buffer

    //the timestamp starts at byte 40 of the received packet and is four bytes,
    // or two words, long. First, esxtract the two words:

    unsigned long highWord = word(packetBuffer[40], packetBuffer[41]);
    unsigned long lowWord = word(packetBuffer[42], packetBuffer[43]);
    // combine the four bytes (two words) into a long integer
    // this is NTP time (seconds since Jan 1 1900):
    unsigned long secsSince1900 = highWord << 16 | lowWord;
    Serial.print("Seconds since Jan 1 1900 = " );
    Serial.println(secsSince1900);

    // now convert NTP time into everyday time:
    Serial.print("Unix time = ");
    // Unix time starts on Jan 1 1970. In seconds, that's 2208988800:
    const unsigned long seventyYears = 2208988800UL;
    // subtract seventy years:
    unsigned long epoch = secsSince1900 - seventyYears;
    // print Unix time:
    Serial.println(epoch);
    tp.tv_sec = epoch;
    settimeofday(&tp, NULL);


    // print the hour, minute and second:
    Serial.print("The UTC time is ");       // UTC is the time at Greenwich Meridian (GMT)
    Serial.print((epoch  % 86400L) / 3600); // print the hour (86400 equals secs per day)
    Serial.print(':');
    if ( ((epoch % 3600) / 60) < 10 ) {
      // In the first 10 minutes of each hour, we'll want a leading '0'
      Serial.print('0');
    }
    Serial.print((epoch  % 3600) / 60); // print the minute (3600 equals secs per minute)
    Serial.print(':');
    if ( (epoch % 60) < 10 ) {
      // In the first 10 seconds of each minute, we'll want a leading '0'
      Serial.print('0');
    }
    Serial.println(epoch % 60); // print the second
  }

  return result;
}

// send an NTP request to the time server at the given address
unsigned long sendNTPpacket(char* address)
{
  byte packetBuffer[NTP_PACKET_SIZE];

  // set all bytes in the buffer to 0
  memset(packetBuffer, 0, NTP_PACKET_SIZE);
  // Initialize values needed to form NTP request
  // (see URL above for details on the packets)
  packetBuffer[0] = 0b11100011;   // LI, Version, Mode
  packetBuffer[1] = 0;     // Stratum, or type of clock
  packetBuffer[2] = 6;     // Polling Interval
  packetBuffer[3] = 0xEC;  // Peer Clock Precision
  // 8 bytes of zero for Root Delay & Root Dispersion
  packetBuffer[12]  = 49;
  packetBuffer[13]  = 0x4E;
  packetBuffer[14]  = 49;
  packetBuffer[15]  = 52;

  // all NTP fields have been given values, now
  // you can send a packet requesting a timestamp:
  udp.beginPacket(address, 123); //NTP requests are to port 123
  udp.write(packetBuffer, NTP_PACKET_SIZE);
  udp.endPacket();
  delay(1000);
}

static void initTime()
{
  udp.begin(LOCAL_PORT);

  while (true)
  {
    sendNTPpacket(TIME_SERVER); // send an NTP packet to a time server

    if (getNTPResponse())
      break;

    Serial.println("Fetching NTP epoch time failed! Waiting 2 seconds to retry.");
    delay(2000);
  }
}

#endif // AZUREIOTSOCKETETHERNET2_H
