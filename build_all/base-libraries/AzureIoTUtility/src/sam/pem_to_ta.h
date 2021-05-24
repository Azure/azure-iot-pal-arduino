
#ifndef PEM_TO_TA_H
#define PEM_TO_TA_H

#include "bearssl.h"

#define CONV_OK (0)
#define CONV_FAILED_INIT (2)
#define CONV_OUT_OF_MEMORY (27)
#define CONV_SSL_CACERT_BADFILE (77)

int pem_to_ta(const char *cer, 
              size_t cer_len,
              br_x509_trust_anchor **anchors,
              size_t *anchors_len);


#endif