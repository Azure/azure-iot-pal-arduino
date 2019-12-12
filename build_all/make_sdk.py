import os
import shutil
from distutils import dir_util
import sys
import getopt
import glob
import make_sdk_cmds_dict as commands_dict

def pattern_copy(pattern): # helper method
    # Get a list of all the files that match the pattern in specified directory
    fileList = glob.glob(pattern)
    for filePath in fileList:
        try:
            shutil.copy2(filePath)
        except:
            print("Error while copying file : ", filePath)


def pattern_delete(pattern): # helper method
    # Get a list of all the files that match the pattern in specified directory
    fileList = glob.glob(pattern)
    # Iterate over the list of filepaths & remove each file.
    for filePath in fileList:
        try:
            os.remove(filePath)
        except:
            print("Error while deleting file : ", filePath)


def pattern_delete_folder(pattern): # helper method
    # Get a list of all the file paths that match the pattern in specified directory
    fileList = glob.glob(pattern)
    # Iterate over the list of filepaths & remove each file.
    for filePath in fileList:
        try:
            # os.rmdir(filePath)
            shutil.rmtree(filePath)
        except:
            print("Error while deleting filepath : ", filePath)


def usage():
    # Iterates through command dictionary to print out script's opt usage
    usage_txt = "make_sdk.py accepts the following arguments: \r\n"

    for commands in commands_dict.cmds:
        usage_txt += " - %s: " %commands + commands_dict.cmds[commands]['text'] + "\r\n"

    return usage_txt

def parse_opts():
    options, remainder = getopt.gnu_getopt(sys.argv[1:], 'ho:d:', ['output', 'help', 'device'])
    # print('OPTIONS   :', options)
    for opt, arg in options:
        if opt in ('-h', '--help'):
            print(usage())
        elif opt in ('-o', '--output'):
            commands_dict.output_path = arg
        elif opt in ('-d', '--device'):
            commands_dict.device_type = arg


def run():
    # set up paths for copying
    obo_path = os.path.abspath(commands_dict.output_path)
    arduino_repo_root = os.path.abspath('../')
    print(obo_path)
    arduino_pal_path = arduino_repo_root+'/pal/'
    azure_iot_sdk_path = arduino_repo_root+'/sdk/'
    AzureIoTHub_path = obo_path+'/AzureIoTHub/'
    AzureIoTProtocolHTTP_path = obo_path+'/AzureIoTProtocol_HTTP/'
    AzureIoTProtocolMQTT_path = obo_path+'/AzureIoTProtocol_MQTT/'
    AzureIoTUtility_path = obo_path+'/AzureIoTUtility/'
    AzureIoTSocketWiFi_path = obo_path+'/AzureIoTSocket_WiFi/'
    # AzureIoTSocketEthernet_path = obo_path+'/AzureIoTSocket_Ethernet/'
    AzureUHTTP_path = AzureIoTProtocolHTTP_path+'src/azure_uhttp_c/'
    AzureUMQTT_path = AzureIoTProtocolMQTT_path+'src/azure_umqtt_c/'
    SharedUtility_path = AzureIoTUtility_path+'src/azure_c_shared_utility/'
    Adapters_path = AzureIoTUtility_path+'src/adapters/'
    Macro_Utils_path = AzureIoTUtility_path+'src/azure_c_shared_utility/azure_macro_utils/'
    Hub_Macro_Utils_path = AzureIoTHub_path+'src/azure_macro_utils/'
    Umock_c_path = AzureIoTUtility_path+'src/umock_c/'
    sdk_path = AzureIoTHub_path+'src/'
    internal_path = AzureIoTHub_path+'src/internal/'

    if (os.path.exists(obo_path)):
        #clear it out
        # shutil.rmtree(obo_path+'/Azure*')
        pattern_delete_folder(obo_path+'/Azure*')
    else:
        os.mkdir(obo_path)

    os.system('ls '+obo_path) # linux only
    input('this?')

    dir_util.copy_tree(arduino_repo_root+'/build_all/base-libraries/AzureIoTHub', AzureIoTHub_path)
    dir_util.copy_tree(arduino_repo_root+'/build_all/base-libraries/AzureIoTUtility', AzureIoTUtility_path)
    dir_util.copy_tree(arduino_repo_root+'/build_all/base-libraries/AzureIoTProtocol_HTTP', AzureIoTProtocolHTTP_path)
    dir_util.copy_tree(arduino_repo_root+'/build_all/base-libraries/AzureIoTProtocol_MQTT', AzureIoTProtocolMQTT_path)
    dir_util.copy_tree(arduino_repo_root+'/build_all/base-libraries/AzureIoTSocket_WiFi', AzureIoTSocketWiFi_path)
    # dir_util.copy_tree(arduino_repo_root+'/build_all/base-libraries/AzureIoTSocket_Ethernet2', AzureIoTSocketEthernet_path)

    # os.mkdir(sdk_path)
    # os.mkdir(internal_path)

    shutil.copy2(azure_iot_sdk_path+'LICENSE', AzureIoTHub_path+'LICENSE')

    dir_util.copy_tree(azure_iot_sdk_path+'iothub_client/src/', sdk_path)
    dir_util.copy_tree(azure_iot_sdk_path+'iothub_client/inc/', sdk_path)
    dir_util.copy_tree(azure_iot_sdk_path+'iothub_client/inc/internal/', internal_path)
    dir_util.copy_tree(azure_iot_sdk_path+'serializer/src/', sdk_path)
    dir_util.copy_tree(azure_iot_sdk_path+'serializer/inc/', sdk_path)
    shutil.copy2(azure_iot_sdk_path+'deps/parson/parson.h', sdk_path)
    shutil.copy2(azure_iot_sdk_path+'deps/parson/parson.c', sdk_path)

    os.mkdir(SharedUtility_path)
    os.mkdir(Adapters_path)
    os.mkdir(Umock_c_path)
    os.mkdir(Umock_c_path+'aux_inc/')
    os.mkdir(Umock_c_path+'azure_macro_utils/')
    os.mkdir(Macro_Utils_path)
    os.mkdir(Hub_Macro_Utils_path)
    os.mkdir(AzureIoTHub_path+'examples/')
    os.mkdir(AzureIoTHub_path+'examples/iothub_ll_telemetry_sample/')
    os.mkdir(AzureIoTHub_path+'src/certs/')

    dir_util.copy_tree(arduino_pal_path+'samples/esp8266/', AzureIoTHub_path+'examples/iothub_ll_telemetry_sample/')
    dir_util.copy_tree(azure_iot_sdk_path+'c-utility/inc/azure_c_shared_utility/', SharedUtility_path)
    dir_util.copy_tree(azure_iot_sdk_path+'c-utility/src/', SharedUtility_path)
    dir_util.copy_tree(arduino_pal_path+'azure_c_shared_utility/', SharedUtility_path)
    dir_util.copy_tree(azure_iot_sdk_path+'deps/umock-c/inc/umock_c/', Umock_c_path)
    dir_util.copy_tree(azure_iot_sdk_path+'deps/umock-c/src/', Umock_c_path)
    dir_util.copy_tree(azure_iot_sdk_path+'deps/azure-macro-utils-c/inc/azure_macro_utils/', Hub_Macro_Utils_path)
    dir_util.copy_tree(azure_iot_sdk_path+'deps/azure-macro-utils-c/inc/azure_macro_utils/', Macro_Utils_path)
    dir_util.copy_tree(azure_iot_sdk_path+'deps/azure-macro-utils-c/inc/azure_macro_utils/', Umock_c_path+'azure_macro_utils/')
    dir_util.copy_tree(azure_iot_sdk_path+'certs/', AzureIoTHub_path+'src/certs/')

    shutil.copy2(azure_iot_sdk_path+'c-utility/pal/agenttime.c', Adapters_path)
    shutil.copy2(azure_iot_sdk_path+'c-utility/pal/tickcounter.c', Adapters_path)
    # dir_util.copy_tree(azure_iot_sdk_path+'deps/azure-macro-utils-c/inc/', Ma)
    shutil.copy2(azure_iot_sdk_path+'c-utility/pal/generic/refcount_os.h', SharedUtility_path)
    shutil.copy2(azure_iot_sdk_path+'c-utility/pal/tlsio_options.c', SharedUtility_path)

    dir_util.copy_tree(arduino_pal_path+'inc/', Adapters_path)
    dir_util.copy_tree(arduino_pal_path+'src/', Adapters_path)

    if commands_dict.device_type == 'esp32': # include mbedtls adapter
        shutil.copy2(azure_iot_sdk_path+'c-utility/adapters/tlsio_mbedtls.c', Adapters_path)
        shutil.copy2(azure_iot_sdk_path+'c-utility/inc/azure_c_shared_utility/tlsio_mbedtls.h', Adapters_path)

    os.mkdir(AzureUHTTP_path)
    shutil.copy2(azure_iot_sdk_path+'c-utility/adapters/httpapi_compact.c', AzureUHTTP_path)

    os.mkdir(AzureUMQTT_path)
    dir_util.copy_tree(azure_iot_sdk_path+'umqtt/src/', AzureUMQTT_path)
    dir_util.copy_tree(azure_iot_sdk_path+'umqtt/inc/', AzureIoTHub_path+'src/')

    shutil.copy2(arduino_pal_path+'AzureIoTSocket_WiFi/socketio_esp32wifi.cpp', AzureIoTSocketWiFi_path+'src/')
    # shutil.copy2(arduino_pal_path+'AzureIoTSocket_Ethernet/socketio_esp32ethernet2.cpp', AzureIoTSocketEthernet_path+'src/')

    # ---- clean out files not needed ----
    os.remove(sdk_path+'blob.c')
    os.remove(internal_path+'blob.h')
    os.remove(SharedUtility_path+'http_proxy_io.c')

    pattern_delete(sdk_path+'*amqp*.*')
    pattern_delete(sdk_path+'iothubtransportmqtt_websockets.*')
    pattern_delete(Adapters_path+'tlsio_bearssl*')
    pattern_delete(SharedUtility_path+'tlsio_cyclonessl*.*')
    pattern_delete(SharedUtility_path+'tlsio_openssl*.*')
    pattern_delete(SharedUtility_path+'tlsio_bearssl*.*')
    pattern_delete(SharedUtility_path+'tlsio_schannel*.*')
    pattern_delete(SharedUtility_path+'tlsio_wolfssl*.*')
    pattern_delete(SharedUtility_path+'gbnetwork.*')
    pattern_delete(SharedUtility_path+'dns_resolver*')
    pattern_delete(SharedUtility_path+'logging_stacktrace*')
    pattern_delete(SharedUtility_path+'wsio*.*')
    pattern_delete(SharedUtility_path+'x509_*.*')
    pattern_delete(SharedUtility_path + 'etw*.*')


if __name__ == '__main__':
    parse_opts()
    run()
