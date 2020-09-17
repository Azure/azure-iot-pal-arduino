// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

// This will only be defined if the library has been included in the IDE
#ifdef ARDUINO_ARCH_ESP8266
#include "ESP8266WiFi.h"
#elif ARDUINO_ARCH_ESP32
#include "WiFi.h"
#else
#include "WiFi101.h"
#endif

#include "azure_c_shared_utility/singlylinkedlist.h"
#include "azure_c_shared_utility/gballoc.h"
#include "azure_c_shared_utility/optimize_size.h"
#include "azure_c_shared_utility/optionhandler.h"
#include "azure_c_shared_utility/shared_util_options.h"
#include "azure_c_shared_utility/xlogging.h"
#include "azure_c_shared_utility/const_defines.h"
#include "azure_c_shared_utility/xio.h"
#include "azure_c_shared_utility/socketio.h"

typedef enum IO_STATE_TAG
{
    IO_STATE_CLOSED,
    IO_STATE_OPENING,
    IO_STATE_OPEN,
    IO_STATE_CLOSING,
    IO_STATE_ERROR
} IO_STATE;

typedef struct PENDING_SOCKET_IO_TAG
{
    unsigned char* bytes;
    size_t size;
    ON_SEND_COMPLETE on_send_complete;
    void* callback_context;
    SINGLYLINKEDLIST_HANDLE pending_io_list;
} PENDING_SOCKET_IO;

typedef struct SOCKET_IO_INSTANCE_TAG
{
    WiFiClient *socket;
    ON_BYTES_RECEIVED on_bytes_received;
    ON_IO_ERROR on_io_error;
    void* on_bytes_received_context;
    void* on_io_error_context;
    char* hostname;
    int port;
    char* target_mac_address;
    IO_STATE io_state;
    SINGLYLINKEDLIST_HANDLE pending_io_list;
    unsigned char recv_bytes[XIO_RECEIVE_BUFFER_SIZE];
} SOCKET_IO_INSTANCE;

typedef struct NETWORK_INTERFACE_DESCRIPTION_TAG
{
    char* name;
    char* mac_address;
    char* ip_address;
    struct NETWORK_INTERFACE_DESCRIPTION_TAG* next;
} NETWORK_INTERFACE_DESCRIPTION;

/*this function will clone an option given by name and value*/
static void* socketio_CloneOption(const char* name, const void* value)
{
    LogError("Cannot clone option %s (not supported)", name);

    return NULL;
}

/*this function destroys an option previously created*/
static void socketio_DestroyOption(const char* name, const void* value)
{
}

static OPTIONHANDLER_HANDLE socketio_retrieveoptions(CONCRETE_IO_HANDLE handle)
{
    OPTIONHANDLER_HANDLE result;

    if (handle == NULL)
    {
        LogError("failed retrieving options (handle is NULL)");
        result = NULL;
    }
    else
    {
        SOCKET_IO_INSTANCE* socket_io_instance = (SOCKET_IO_INSTANCE*)handle;

        result = OptionHandler_Create(socketio_CloneOption, socketio_DestroyOption, socketio_setoption);
        if (result == NULL)
        {
            LogError("unable to OptionHandler_Create");
        }
        else if (socket_io_instance->target_mac_address != NULL &&
            OptionHandler_AddOption(result, OPTION_NET_INT_MAC_ADDRESS, socket_io_instance->target_mac_address) != OPTIONHANDLER_OK)
        {
            LogError("failed retrieving options (failed adding net_interface_mac_address)");
            OptionHandler_Destroy(result);
            result = NULL;
        }
    }

    return result;
}

static const IO_INTERFACE_DESCRIPTION socket_io_interface_description =
{
    socketio_retrieveoptions,
    socketio_create,
    socketio_destroy,
    socketio_open,
    socketio_close,
    socketio_send,
    socketio_dowork,
    socketio_setoption
};

static void indicate_error(SOCKET_IO_INSTANCE* socket_io_instance)
{
    socket_io_instance->io_state = IO_STATE_ERROR;
    if (socket_io_instance->on_io_error != NULL)
    {
        socket_io_instance->on_io_error(socket_io_instance->on_io_error_context);
    }
}

static int add_pending_io(SOCKET_IO_INSTANCE* socket_io_instance, const unsigned char* buffer, size_t size, ON_SEND_COMPLETE on_send_complete, void* callback_context)
{
    int result;

    PENDING_SOCKET_IO* pending_socket_io = (PENDING_SOCKET_IO*)malloc(sizeof(PENDING_SOCKET_IO));
    if (pending_socket_io == NULL)
    {
        result = MU_FAILURE;
    }
    else
    {
        pending_socket_io->bytes = (unsigned char*)malloc(size);
        if (pending_socket_io->bytes == NULL)
        {
            LogError("Allocation Failure: Unable to allocate pending list.");
            free(pending_socket_io);
            result = MU_FAILURE;
        }
        else
        {
            pending_socket_io->size = size;
            pending_socket_io->on_send_complete = on_send_complete;
            pending_socket_io->callback_context = callback_context;
            pending_socket_io->pending_io_list = socket_io_instance->pending_io_list;
            (void)memcpy(pending_socket_io->bytes, buffer, size);

            if (singlylinkedlist_add(socket_io_instance->pending_io_list, pending_socket_io) == NULL)
            {
                LogError("Failure: Unable to add socket to pending list.");
                free(pending_socket_io->bytes);
                free(pending_socket_io);
                result = MU_FAILURE;
            }
            else
            {
                result = 0;
            }
        }
    }

    return result;
}

CONCRETE_IO_HANDLE socketio_create(void* io_create_parameters)
{
    SOCKETIO_CONFIG* socket_io_config = (SOCKETIO_CONFIG*)io_create_parameters;
    SOCKET_IO_INSTANCE* result;

    if (socket_io_config == NULL)
    {
        LogError("Invalid argument: socket_io_config is NULL");
        result = NULL;
    }
    else
    {
        result = (SOCKET_IO_INSTANCE*)malloc(sizeof(SOCKET_IO_INSTANCE));
        if (result != NULL)
        {
            result->pending_io_list = singlylinkedlist_create();
            if (result->pending_io_list == NULL)
            {
                LogError("Failure: singlylinkedlist_create unable to create pending list.");
                free(result);
                result = NULL;
            }
            else
            {
                if (socket_io_config->hostname != NULL)
                {
                    result->hostname = (char*)malloc(strlen(socket_io_config->hostname) + 1);
                    if (result->hostname != NULL)
                    {
                        (void)strcpy(result->hostname, socket_io_config->hostname);
                    }

                    result->socket = NULL;
                }
                else
                {
                    result->hostname = NULL;
                    result->socket = (WiFiClient*)socket_io_config->accepted_socket;
                }

                if ((result->hostname == NULL) && (result->socket == NULL))
                {
                    LogError("Failure: hostname == NULL and socket is invalid.");
                    singlylinkedlist_destroy(result->pending_io_list);
                    free(result);
                    result = NULL;
                }
                else
                {
                    result->port = socket_io_config->port;
                    result->target_mac_address = NULL;
                    result->on_bytes_received = NULL;
                    result->on_io_error = NULL;
                    result->on_bytes_received_context = NULL;
                    result->on_io_error_context = NULL;
                    result->io_state = IO_STATE_CLOSED;
                }
            }
        }
        else
        {
            LogError("Allocation Failure: SOCKET_IO_INSTANCE");
        }
    }

    return result;
}

void socketio_destroy(CONCRETE_IO_HANDLE socket_io)
{
    if (socket_io != NULL)
    {
        SOCKET_IO_INSTANCE* socket_io_instance = (SOCKET_IO_INSTANCE*)socket_io;
        /* we cannot do much if the close fails, so just ignore the result */
        if (socket_io_instance->socket != NULL)
        {
            if (socket_io_instance->hostname != NULL)
            {
                // We created this socket so delete it
                delete socket_io_instance->socket;
            }
            socket_io_instance->socket = NULL;
        }

        /* clear all pending IOs */
        LIST_ITEM_HANDLE first_pending_io = singlylinkedlist_get_head_item(socket_io_instance->pending_io_list);
        while (first_pending_io != NULL)
        {
            PENDING_SOCKET_IO* pending_socket_io = (PENDING_SOCKET_IO*)singlylinkedlist_item_get_value(first_pending_io);
            if (pending_socket_io != NULL)
            {
                free(pending_socket_io->bytes);
                free(pending_socket_io);
            }

            (void)singlylinkedlist_remove(socket_io_instance->pending_io_list, first_pending_io);
            first_pending_io = singlylinkedlist_get_head_item(socket_io_instance->pending_io_list);
        }

        singlylinkedlist_destroy(socket_io_instance->pending_io_list);
        free(socket_io_instance->hostname);
        free(socket_io_instance->target_mac_address);
        free(socket_io);
    }
}

int socketio_open(CONCRETE_IO_HANDLE socket_io, ON_IO_OPEN_COMPLETE on_io_open_complete, void* on_io_open_complete_context, ON_BYTES_RECEIVED on_bytes_received, void* on_bytes_received_context, ON_IO_ERROR on_io_error, void* on_io_error_context)
{
    int result;

    SOCKET_IO_INSTANCE* socket_io_instance = (SOCKET_IO_INSTANCE*)socket_io;
    if (socket_io == NULL)
    {
        LogError("Invalid argument: SOCKET_IO_INSTANCE is NULL");
        result = MU_FAILURE;
    }
    else
    {
        if (socket_io_instance->io_state != IO_STATE_CLOSED)
        {
            LogError("Failure: socket state is not closed.");
            result = MU_FAILURE;
        }
        else if (socket_io_instance->socket != NULL)
        {
            // Opening an accepted socket
            socket_io_instance->on_bytes_received_context = on_bytes_received_context;
            socket_io_instance->on_bytes_received = on_bytes_received;
            socket_io_instance->on_io_error = on_io_error;
            socket_io_instance->on_io_error_context = on_io_error_context;

            socket_io_instance->io_state = IO_STATE_OPEN;

            result = 0;
        }
        else
        {
            socket_io_instance->socket = new WiFiClient();

            if (socket_io_instance->socket == NULL)
            {
                LogError("Failure: socket create failure %d.", socket_io_instance->socket);
                result = MU_FAILURE;
            }
            else if (!socket_io_instance->socket->connect(socket_io_instance->hostname, socket_io_instance->port) != 0)
            {
                LogError("Socket connect failed");
                result = MU_FAILURE;
            }
            else
            {
                result = 0;
            }

            if (result == 0)
            {
                socket_io_instance->on_bytes_received = on_bytes_received;
                socket_io_instance->on_bytes_received_context = on_bytes_received_context;

                socket_io_instance->on_io_error = on_io_error;
                socket_io_instance->on_io_error_context = on_io_error_context;

                socket_io_instance->io_state = IO_STATE_OPEN;
            }
            else
            {
                if (socket_io_instance->socket != NULL)
                {
                    delete socket_io_instance->socket;
                    socket_io_instance->socket = NULL;
                }
            }
        }
    }

    if (on_io_open_complete != NULL)
    {
        on_io_open_complete(on_io_open_complete_context, result == 0 ? IO_OPEN_OK : IO_OPEN_ERROR);
    }

    return result;
}

int socketio_close(CONCRETE_IO_HANDLE socket_io, ON_IO_CLOSE_COMPLETE on_io_close_complete, void* callback_context)
{
    int result;

    if (socket_io == NULL)
    {
        result = MU_FAILURE;
    }
    else
    {
        SOCKET_IO_INSTANCE* socket_io_instance = (SOCKET_IO_INSTANCE*)socket_io;

        if ((socket_io_instance->io_state != IO_STATE_CLOSED) && (socket_io_instance->io_state != IO_STATE_CLOSING))
        {
            // Only close if the socket isn't already in the closed or closing state
            if (socket_io_instance->socket != NULL)
            {
                socket_io_instance->socket->stop();
            }

            if (socket_io_instance->hostname != NULL)
            {
                // We created this socket so delete it
                delete socket_io_instance->socket;
            }

            socket_io_instance->socket = NULL;
            socket_io_instance->io_state = IO_STATE_CLOSED;
        }

        if (on_io_close_complete != NULL)
        {
            on_io_close_complete(callback_context);
        }

        result = 0;
    }

    return result;
}

int socketio_send(CONCRETE_IO_HANDLE socket_io, const void* buffer, size_t size, ON_SEND_COMPLETE on_send_complete, void* callback_context)
{
    int result;

    if ((socket_io == NULL) ||
        (buffer == NULL) ||
        (size == 0))
    {
        /* Invalid arguments */
        LogError("Invalid argument: send given invalid parameter");
        result = MU_FAILURE;
    }
    else
    {
        SOCKET_IO_INSTANCE* socket_io_instance = (SOCKET_IO_INSTANCE*)socket_io;
        if (socket_io_instance->io_state != IO_STATE_OPEN)
        {
            LogError("Failure: socket state is not opened.");
            result = MU_FAILURE;
        }
        else
        {
            LIST_ITEM_HANDLE first_pending_io = singlylinkedlist_get_head_item(socket_io_instance->pending_io_list);
            if (first_pending_io != NULL)
            {
                if (add_pending_io(socket_io_instance, (const unsigned char*)buffer, size, on_send_complete, callback_context) != 0)
                {
                    LogError("Failure: add_pending_io failed.");
                    result = MU_FAILURE;
                }
                else
                {
                    result = 0;
                }
            }
            else
            {
                ssize_t send_result = socket_io_instance->socket->write((const uint8_t *)buffer, size);

                if (send_result == 0)
                {
                    LogError("Failure: sending socket failed. errno=%d (%s).", errno, strerror(errno));
                    result = MU_FAILURE;
                }
                else if (send_result < size)
                {
                    /* queue data */
                    if (add_pending_io(socket_io_instance, (const unsigned char*)(buffer + send_result), size - send_result, on_send_complete, callback_context) != 0)
                    {
                        LogError("Failure: add_pending_io failed.");
                        result = MU_FAILURE;
                    }
                    else
                    {
                        size_t bytes_sent = (send_result < 0 ? 0 : send_result);
                        result = 0;
                    }
                }
                else
                {
                    if (on_send_complete != NULL)
                    {
                        on_send_complete(callback_context, IO_SEND_OK);
                    }

                    result = 0;
                }
            }
        }
    }

    return result;
}

void socketio_dowork(CONCRETE_IO_HANDLE socket_io)
{
    if (socket_io != NULL)
    {
        SOCKET_IO_INSTANCE* socket_io_instance = (SOCKET_IO_INSTANCE*)socket_io;
        LIST_ITEM_HANDLE first_pending_io = singlylinkedlist_get_head_item(socket_io_instance->pending_io_list);
        while (first_pending_io != NULL)
        {
            PENDING_SOCKET_IO* pending_socket_io = (PENDING_SOCKET_IO*)singlylinkedlist_item_get_value(first_pending_io);
            if (pending_socket_io == NULL)
            {
                indicate_error(socket_io_instance);
                LogError("Failure: retrieving socket from list");
                break;
            }

            ssize_t send_result = socket_io_instance->socket->write(pending_socket_io->bytes, pending_socket_io->size);
            if (send_result == 0)
            {
                free(pending_socket_io->bytes);
                free(pending_socket_io);
                (void)singlylinkedlist_remove(socket_io_instance->pending_io_list, first_pending_io);

                LogError("Failure: sending Socket information");
                indicate_error(socket_io_instance);
            }
            else if (send_result < pending_socket_io->size)
            {
                /* simply wait until next dowork */
                (void)memmove(pending_socket_io->bytes, pending_socket_io->bytes + send_result, pending_socket_io->size - send_result);
                pending_socket_io->size -= send_result;
                break;
            }
            else
            {
                if (pending_socket_io->on_send_complete != NULL)
                {
                    pending_socket_io->on_send_complete(pending_socket_io->callback_context, IO_SEND_OK);
                }

                free(pending_socket_io->bytes);
                free(pending_socket_io);
                if (singlylinkedlist_remove(socket_io_instance->pending_io_list, first_pending_io) != 0)
                {
                    indicate_error(socket_io_instance);
                    LogError("Failure: unable to remove socket from list");
                }
            }

            first_pending_io = singlylinkedlist_get_head_item(socket_io_instance->pending_io_list);
        }

        if (socket_io_instance->io_state == IO_STATE_OPEN)
        {
            ssize_t received = 0;

            while (socket_io_instance->socket->available() && socket_io_instance->io_state == IO_STATE_OPEN)
            {
                received = socket_io_instance->socket->read(socket_io_instance->recv_bytes, XIO_RECEIVE_BUFFER_SIZE);

                if (received > 0)
                {
                    if (socket_io_instance->on_bytes_received != NULL)
                    {
                        /* Explicitly ignoring here the result of the callback */
                        (void)socket_io_instance->on_bytes_received(socket_io_instance->on_bytes_received_context, socket_io_instance->recv_bytes, received);
                    }
                }
                else if (received < 0)
                {
                    LogError("Socketio_Failure: Receiving data from endpoint: errno=%d.", errno);
                    indicate_error(socket_io_instance);
                }
            }
        }
    }
}

int socketio_setoption(CONCRETE_IO_HANDLE socket_io, const char* optionName, const void* value)
{
    return 0;
}

const IO_INTERFACE_DESCRIPTION* socketio_get_interface_description(void)
{
    return &socket_io_interface_description;
}
