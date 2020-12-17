
// Code here is pulled from curl sources, with the copyright and license
// shown below. I've extracted just one function (load_cafile) and converted 
// it to read the certificate from a char array instead of a file.


/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 2019 - 2020, Michael Forney, <mforney@mforney.org>
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at https://curl.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 ***************************************************************************/

#include <memory>
#include <vector>
#include "bearssl.h"
#include <stdlib.h>
#include <string.h>
#include <Arduino.h>

#include "pem_to_ta.h"

struct cafile_parser
{
  int err;
  bool in_cert;
  br_x509_decoder_context xc;
  /* array of trust anchors loaded from CAfile */
  br_x509_trust_anchor *anchors;
  size_t anchors_len;
  /* buffer for DN data */
  unsigned char dn[1024];
  size_t dn_len;
};

static void append_dn(void *ctx, const void *buf, size_t len)
{
  struct cafile_parser *ca = (struct cafile_parser *)ctx;

  if (ca->err != 0 || !ca->in_cert)
    return;
  if (sizeof(ca->dn) - ca->dn_len < len)
  {
    ca->err = CONV_FAILED_INIT;
    return;
  }
  memcpy(ca->dn + ca->dn_len, buf, len);
  ca->dn_len += len;
}

static void x509_push(void *ctx, const void *buf, size_t len)
{
  struct cafile_parser *ca = (struct cafile_parser *)ctx;

  if (ca->in_cert)
    br_x509_decoder_push(&ca->xc, buf, len);
}

int pem_to_ta(const char *cer,
             size_t cer_len,
             br_x509_trust_anchor **anchors,
             size_t *anchors_len)
{
  struct cafile_parser ca;
  br_pem_decoder_context pc;
  br_x509_trust_anchor *ta;
  size_t ta_size;
  br_x509_trust_anchor *new_anchors;
  size_t new_anchors_len;
  br_x509_pkey *pkey;
  const char *p;
  const char *name;
  size_t n, i, pushed;

  ca.err = CONV_OK;
  ca.in_cert = 0;
  ca.anchors = NULL;
  ca.anchors_len = 0;
  br_pem_decoder_init(&pc);
  br_pem_decoder_setdest(&pc, x509_push, &ca);
  n = cer_len;
  p = cer;

  while (n)
  {
    pushed = br_pem_decoder_push(&pc, p, n);
    if (ca.err)
      goto fail;
    p += pushed;
    n -= pushed;
    switch (br_pem_decoder_event(&pc))
    {
    case 0:
      break;
    case BR_PEM_BEGIN_OBJ:
      name = br_pem_decoder_name(&pc);
      //if(strcmp(name, "CERTIFICATE") && strcmp(name, "X509 CERTIFICATE"))
      // break;
      br_x509_decoder_init(&ca.xc, append_dn, &ca);
      if (ca.anchors_len == SIZE_MAX / sizeof(ca.anchors[0]))
      {
        ca.err = CONV_OUT_OF_MEMORY;
        goto fail;
      }
      new_anchors_len = ca.anchors_len + 1;
      new_anchors = (br_x509_trust_anchor *)realloc(ca.anchors,
                                                    new_anchors_len * sizeof(ca.anchors[0]));
      if (!new_anchors)
      {
        ca.err = CONV_OUT_OF_MEMORY;
        goto fail;
      }
      ca.anchors = new_anchors;
      ca.anchors_len = new_anchors_len;
      ca.in_cert = 1;
      ca.dn_len = 0;
      ta = &ca.anchors[ca.anchors_len - 1];
      ta->dn.data = NULL;
      break;
    case BR_PEM_END_OBJ:
      if (!ca.in_cert)
        break;
      ca.in_cert = 0;
      if (br_x509_decoder_last_error(&ca.xc))
      {
        ca.err = CONV_SSL_CACERT_BADFILE;
        goto fail;
      }
      ta->flags = 0;
      if (br_x509_decoder_isCA(&ca.xc))
        ta->flags |= BR_X509_TA_CA;
      pkey = br_x509_decoder_get_pkey(&ca.xc);
      if (!pkey)
      {
        ca.err = CONV_SSL_CACERT_BADFILE;
        goto fail;
      }
      ta->pkey = *pkey;

      /* calculate space needed for trust anchor data */
      ta_size = ca.dn_len;
      switch (pkey->key_type)
      {
      case BR_KEYTYPE_RSA:
        ta_size += pkey->key.rsa.nlen + pkey->key.rsa.elen;
        break;
      case BR_KEYTYPE_EC:
        ta_size += pkey->key.ec.qlen;
        break;
      default:
        ca.err = CONV_FAILED_INIT;
        goto fail;
      }

      /* fill in trust anchor DN and public key data */
      ta->dn.data = (unsigned char *)malloc(ta_size);
      if (!ta->dn.data)
      {
        ca.err = CONV_OUT_OF_MEMORY;
        goto fail;
      }
      memcpy(ta->dn.data, ca.dn, ca.dn_len);
      ta->dn.len = ca.dn_len;
      switch (pkey->key_type)
      {
      case BR_KEYTYPE_RSA:
        ta->pkey.key.rsa.n = ta->dn.data + ta->dn.len;
        memcpy(ta->pkey.key.rsa.n, pkey->key.rsa.n, pkey->key.rsa.nlen);
        ta->pkey.key.rsa.e = ta->pkey.key.rsa.n + ta->pkey.key.rsa.nlen;
        memcpy(ta->pkey.key.rsa.e, pkey->key.rsa.e, pkey->key.rsa.elen);
        break;
      case BR_KEYTYPE_EC:
        ta->pkey.key.ec.q = ta->dn.data + ta->dn.len;
        memcpy(ta->pkey.key.ec.q, pkey->key.ec.q, pkey->key.ec.qlen);
        break;
      }
      break;
    default:
      ca.err = CONV_SSL_CACERT_BADFILE;
      goto fail;
    }
  }
  //}

fail:
  if (ca.err == CONV_OK)
  {
    *anchors = ca.anchors;
    *anchors_len = ca.anchors_len;
  }
  else
  {
    for (i = 0; i < ca.anchors_len; ++i)
      free(ca.anchors[i].dn.data);
    free(ca.anchors);
  }

  return ca.err;
}