// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#ifndef SAMPLE_INIT_H
#define SAMPLE_INIT_H

#ifdef ARDUINO_ARCH_SAM
#include <SSLClient.h>


extern br_x509_trust_anchor *g_anchors;
extern size_t g_anchors_len;
extern int g_rand_pin;

void due_sample_init(byte *mac, 
                    const int rand_pin);
#endif

#endif // SAMPLE_INIT_H
