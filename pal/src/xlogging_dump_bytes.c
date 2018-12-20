// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

#include "azure_c_shared_utility/xlogging.h"
#include "azure_c_shared_utility/consolelogger.h"


/* Print up to 16 bytes per line. */
#define LINE_SIZE 16

/* Return the printable char for the provided value. */
#define PRINTABLE(c)         ((c >= ' ') && (c <= '~')) ? (char)c : '.'

/* Convert the lower nibble of the provided byte to a hexadecimal printable char. */
#define HEX_STR(c)           (((c) & 0xF) < 0xA) ? (char)(((c) & 0xF) + '0') : (char)(((c) & 0xF) - 0xA + 'A')

void xlogging_dump_bytes(const void* buf, size_t size)
{
    char charBuf[LINE_SIZE + 1];
    char hexBuf[LINE_SIZE * 3 + 1];
    size_t countbuf = 0;
    const unsigned char* bufAsChar = (const unsigned char*)buf;
    const unsigned char* startPos = bufAsChar;
    LOG(AZ_LOG_TRACE, 0, "Buffer length=%d\r\n", size);

    /* Print the whole buffer. */
    size_t i = 0;
    for (i = 0; i < size; i++)
    {
        /* Store the printable value of the char in the charBuf to print. */
        charBuf[countbuf] = PRINTABLE(*bufAsChar);

        /* Convert the high nibble to a printable hexadecimal value. */
        hexBuf[countbuf * 3] = HEX_STR(*bufAsChar >> 4);

        /* Convert the low nibble to a printable hexadecimal value. */
        hexBuf[countbuf * 3 + 1] = HEX_STR(*bufAsChar);

        hexBuf[countbuf * 3 + 2] = ' ';

        countbuf++;
        bufAsChar++;
        /* If the line is full, print it to start another one. */
        if (countbuf == LINE_SIZE)
        {
            charBuf[countbuf] = '\0';
            hexBuf[countbuf * 3] = '\0';
            LOG(AZ_LOG_TRACE, 0, "%p: %s    %s\r\n", startPos, hexBuf, charBuf);
            countbuf = 0;
            startPos = bufAsChar;
        }
    }

    /* If the last line does not fit the line size. */
    if (countbuf > 0)
    {
        /* Close the charBuf string. */
        charBuf[countbuf] = '\0';

        /* Fill the hexBuf with spaces to keep the charBuf alignment. */
        while ((countbuf++) < LINE_SIZE - 1)
        {
            hexBuf[countbuf * 3] = ' ';
            hexBuf[countbuf * 3 + 1] = ' ';
            hexBuf[countbuf * 3 + 2] = ' ';
        }
        hexBuf[countbuf * 3] = '\0';

        /* Print the last line. */
        LOG(AZ_LOG_TRACE, 0, "%p: %s    %s\r\n", startPos, hexBuf, charBuf);
    }
}
