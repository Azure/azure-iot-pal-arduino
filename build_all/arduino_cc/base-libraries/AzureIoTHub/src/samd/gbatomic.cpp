// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#if defined(ARDUINO_ARCH_SAMD)

#include "gbatomic.h"
#include <Arduino.h>
#include <cstddef>
 
static unsigned int xadd_4(volatile void* pVal, unsigned int value)
{
    unsigned int* pValInt = (unsigned int*)pVal;

    __disable_irq();
    value += *pValInt;
    __enable_irq();

    return value;
}

unsigned int __sync_add_and_fetch_4(volatile void* pVal, unsigned int inc)
{
    return (xadd_4(pVal, inc) + inc);
}

unsigned int __sync_sub_and_fetch_4(volatile void* pVal, unsigned int inc)
{
    return (xadd_4(pVal, -inc) - inc);
}

#endif // #if defined(ARDUINO_ARCH_SAMD)
