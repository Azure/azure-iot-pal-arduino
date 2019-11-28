// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#ifdef ARDUINO_ARCH_ESP32
#include "azcpgmspace.h"
#include <cstddef>
 
char* az_c_strncpy_P(char* dest, PGM_P src, size_t size) {
    return strncpy_P(dest, src, size);
}

size_t az_c_strlen_P(PGM_P s) {
    return strlen_P(s);
}

#endif // ARDUINO_ARCH_ESP32
