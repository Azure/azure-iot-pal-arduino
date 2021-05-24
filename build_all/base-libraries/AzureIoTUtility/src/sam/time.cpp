// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#if defined(ARDUINO_ARCH_SAM)
#include <time.h>
#include <sys/time.h>

#include <RTCDue.h>

RTCDue rtc(XTAL);

extern "C" {
    int _gettimeofday(struct timeval* tp, void* /*tzvp*/)
    {
        tp->tv_sec = rtc.unixtime();
        tp->tv_usec = 0;

        return 0;
    }

    int settimeofday(const struct timeval* tp, const struct timezone* /*tzp*/)
    {
        rtc.begin();
        rtc.setClock(tp->tv_sec); 
        return 0;
    }
}
#endif