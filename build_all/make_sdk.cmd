@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@echo off

REM This script creates the SDK folder with the latest bits from the Azure SDK repository.
REM It removes some files we do not need.

if "%1" equ "" (
    echo make_sdk.cmd requires a single output directory parameter
    exit /b 1
)

set use_mbedtls="true"
if "%2" equ "esp8266" (
    echo building without mbedtls adapter
    set use_mbedtls="false"
)

set Libraries_path=%1

rem // The location of the Azure IoT SDK relative to this file
set arduino_repo_root=%~dp0..\
rem // resolve to fully qualified path
for %%i in ("%arduino_repo_root%") do set arduino_repo_root=%%~fi

rem // The location of the Arduino PAL directory relative to this file
set Arduino_pal_path=%arduino_repo_root%pal\
set AzureIoTSDKs_path=%arduino_repo_root%sdk\

set AzureIoTHub_path=%Libraries_path%\AzureIoTHub\
set AzureIoTProtocolHTTP_path=%Libraries_path%\AzureIoTProtocol_HTTP\
set AzureIoTProtocolMQTT_path=%Libraries_path%\AzureIoTProtocol_MQTT\

set AzureIoTUtility_path=%Libraries_path%\AzureIoTUtility\
set AzureIoTSocketWiFi_path=%Libraries_path%\AzureIoTSocket_WiFi\
set AzureIoTSocketEthernet_path=%Libraries_path%\AzureIoTSocket_Ethernet2\

set AzureUHTTP_path=%AzureIoTProtocolHTTP_path%src\azure_uhttp_c\
set AzureUMQTT_path=%AzureIoTProtocolMQTT_path%src\azure_umqtt_c\

set SharedUtility_path=%AzureIoTUtility_path%src\azure_c_shared_utility\
set Adapters_path=%AzureIoTUtility_path%src\adapters\
set Macro_Utils_path=%AzureIoTUtility_path%src\azure_c_shared_utility\azure_macro_utils\
set Hub_Macro_Utils_path=%AzureIoTHub_path%src\azure_macro_utils\
set Umock_c_path=%AzureIoTUtility_path%src\umock_c\
set MbedTLS_path=%Arduino_pal_path%mbedtls\
set sdk_path=%AzureIoTHub_path%src\
set internal_path=%AzureIoTHub_path%\src\internal\

mkdir %Libraries_path%
pushd %Libraries_path%

if exist "%AzureIoTHub_path%" rd /s /q %AzureIoTHub_path%

robocopy %~dp0\base-libraries\AzureIoTHub %AzureIoTHub_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTUtility %AzureIoTUtility_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTProtocol_HTTP %AzureIoTProtocolHTTP_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTProtocol_MQTT %AzureIoTProtocolMQTT_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTSocket_WiFi %AzureIoTSocketWiFi_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTSocket_Ethernet2 %AzureIoTSocketEthernet_path% -MIR

mkdir %sdk_path%
mkdir %internal_path%

cd /D %AzureIoTSDKs_path%
rem echo Upstream HEAD @ > %sdk_path%metadata.txt
rem git rev-parse HEAD >> %sdk_path%metadata.txt

echo arduino_repo_root: %arduino_repo_root%

copy %AzureIoTSDKs_path%LICENSE %AzureIoTHub_path%LICENSE

copy %AzureIoTSDKs_path%iothub_client\src\ %sdk_path%
copy %AzureIoTSDKs_path%iothub_client\inc\ %sdk_path%
copy %AzureIoTSDKs_path%iothub_client\inc\internal %internal_path%
copy %AzureIoTSDKs_path%serializer\src\ %sdk_path%
copy %AzureIoTSDKs_path%serializer\inc\ %sdk_path%
copy %AzureIoTSDKs_path%deps\parson\parson.* %sdk_path%

mkdir %SharedUtility_path%
mkdir %Adapters_path%
mkdir %Umock_c_path%
mkdir %Umock_c_path%aux_inc\
mkdir %Umock_c_path%azure_macro_utils\
mkdir %Macro_Utils_path%
mkdir %Hub_Macro_Utils_path%
mkdir %AzureIoTHub_path%examples\iothub_ll_telemetry_sample\
mkdir %AzureIoTHub_path%src\certs\

copy %Arduino_pal_path%samples\esp8266\* %AzureIoTHub_path%examples\iothub_ll_telemetry_sample
copy %AzureIoTSDKs_path%c-utility\inc\azure_c_shared_utility %SharedUtility_path%
copy %AzureIoTSDKs_path%c-utility\src\ %SharedUtility_path%
copy /y %Arduino_pal_path%\azure_c_shared_utility\*.* %SharedUtility_path%
copy %AzureIoTSDKs_path%deps\umock-c\inc\umock_c\ %Umock_c_path%
copy %AzureIoTSDKs_path%deps\umock-c\inc\umock_c\aux_inc\ %Umock_c_path%aux_inc\
copy %AzureIoTSDKs_path%deps\umock-c\src\ %Umock_c_path%
copy %AzureIoTSDKs_path%deps\azure-macro-utils-c\inc\azure_macro_utils\ %Hub_Macro_Utils_path%
copy %AzureIoTSDKs_path%deps\azure-macro-utils-c\inc\azure_macro_utils\ %Macro_Utils_path%
copy %AzureIoTSDKs_path%deps\azure-macro-utils-c\inc\azure_macro_utils\ %Umock_c_path%azure_macro_utils\
copy %AzureIoTSDKs_path%certs\ %AzureIoTHub_path%src\certs\

copy %AzureIoTSDKs_path%c-utility\pal\agenttime.c %Adapters_path%
copy %AzureIoTSDKs_path%c-utility\pal\tickcounter.c %Adapters_path%
copy %AzureIoTSDKs_path%deps\azure-macro-utils-c\inc\ %Azure_macro_utils_path%
rem // Bring in the generic refcount_os.h
copy %AzureIoTSDKs_path%c-utility\pal\generic\refcount_os.h %SharedUtility_path%
rem // and tlsio_options.c
copy %AzureIoTSDKs_path%c-utility\pal\tlsio_options.c %SharedUtility_path%

rem // Copy the Arduino-specific files from the Arduino PAL path
copy %Arduino_pal_path%inc\*.* %Adapters_path%
copy %Arduino_pal_path%src\*.* %Adapters_path%

if %use_mbedtls% equ "true" (
rem // Use the MbedTLS adaptor instead of the above
copy %AzureIoTSDKs_path%c-utility\adapters\tlsio_mbedtls.c %Adapters_path%
copy %AzureIoTSDKs_path%c-utility\inc\azure_c_shared_utility\tlsio_mbedtls.h %Adapters_path%
)


mkdir %AzureUHTTP_path%
copy %AzureIoTSDKs_path%c-utility\adapters\httpapi_compact.c %AzureUHTTP_path%

mkdir %AzureUMQTT_path%
copy %AzureIoTSDKs_path%umqtt\src %AzureUMQTT_path%
mkdir %AzureIoTHub_path%src\azure_umqtt_c\
copy %AzureIoTSDKs_path%umqtt\inc\azure_umqtt_c %AzureIoTHub_path%src\azure_umqtt_c\

copy %Arduino_pal_path%AzureIoTSocket_WiFi\socketio_esp32wifi.cpp %AzureIoTSocketWiFi_path%src
@echo %Arduino_pal_path%AzureIoTSocket_Ethernet\socketio_esp32ethernet2.cpp
@echo %AzureIoTSocketEthernet_path%src
copy %Arduino_pal_path%AzureIoTSocket_Ethernet\socketio_esp32ethernet2.cpp %AzureIoTSocketEthernet_path%src

del %sdk_path%*amqp*.*
del %sdk_path%iothubtransportmqtt_websockets.*
del %sdk_path%blob.c
del %internal_path%blob.h
del %Adapters_path%tlsio_bearssl*

del %SharedUtility_path%tlsio_cyclonessl*.*
del %SharedUtility_path%tlsio_openssl.*
del %SharedUtility_path%tlsio_bearssl.*
del %SharedUtility_path%tlsio_schannel.*
del %SharedUtility_path%tlsio_wolfssl.*
del %SharedUtility_path%gbnetwork.*
del %SharedUtility_path%dns_resolver*
del %SharedUtility_path%logging_stacktrace*
del %SharedUtility_path%wsio*.*
del %SharedUtility_path%x509_*.*
del %SharedUtility_path%etw*.*
del %SharedUtility_path%http_proxy_io.c

popd
