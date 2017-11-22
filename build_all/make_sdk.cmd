@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@echo off

REM This script creates the SDK folder with the latest bits from the Azure SDK repository.
REM It removes some files we do not need.

if "%1" equ "" (
    echo make_sdk.cmd requires a single output directory parameter
    exit /b 1
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
set AzureIoTProtocolAMQP_path=%Libraries_path%\AzureIoTProtocol_AMQP\
set AzureIoTUtility_path=%Libraries_path%\AzureIoTUtility\

set AzureUHTTP_path=%AzureIoTProtocolHTTP_path%src\azure_uhttp_c\
set AzureUMQTT_path=%AzureIoTProtocolMQTT_path%src\azure_umqtt_c\
set AzureUAMQP_path=%AzureIoTProtocolAMQP_path%src\azure_uamqp_c\
set SharedUtility_path=%AzureIoTUtility_path%src\azure_c_shared_utility\
set Adapters_path=%AzureIoTUtility_path%src\adapters\
set sdk_path=%AzureIoTHub_path%src\sdk\

mkdir %Libraries_path%
pushd %Libraries_path%

if exist "%AzureIoTHub_path%" rd /s /q %AzureIoTHub_path%

robocopy %~dp0\base-libraries\AzureIoTHub %AzureIoTHub_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTUtility %AzureIoTUtility_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTProtocol_HTTP %AzureIoTProtocolHTTP_path% -MIR
robocopy %~dp0\base-libraries\AzureIoTProtocol_MQTT %AzureIoTProtocolMQTT_path% -MIR

mkdir %sdk_path%

cd /D %AzureIoTSDKs_path%
rem echo Upstream HEAD @ > %sdk_path%metadata.txt
rem git rev-parse HEAD >> %sdk_path%metadata.txt

echo arduino_repo_root: %arduino_repo_root%

copy %AzureIoTSDKs_path%LICENSE %AzureIoTHub_path%LICENSE

copy %AzureIoTSDKs_path%iothub_client\src\ %sdk_path%
copy %AzureIoTSDKs_path%iothub_client\inc\ %sdk_path%
copy %AzureIoTSDKs_path%serializer\src\ %sdk_path%
copy %AzureIoTSDKs_path%serializer\inc\ %sdk_path%
copy %AzureIoTSDKs_path%deps\parson\parson.* %sdk_path%
copy %AzureIoTSDKs_path%serializer\samples\simplesample_http\simplesample_http.* %AzureIoTHub_path%examples\simplesample_http
copy %AzureIoTSDKs_path%serializer\samples\simplesample_http\simplesample_http.* %AzureIoTProtocolHTTP_path%examples\simplesample_http
copy %AzureIoTSDKs_path%serializer\samples\simplesample_mqtt\simplesample_mqtt.* %AzureIoTProtocolMQTT_path%examples\simplesample_mqtt
copy %AzureIoTSDKs_path%serializer\samples\simplesample_http\simplesample_http.* %AzureIoTUtility_path%examples\simplesample_http

mkdir %SharedUtility_path%
mkdir %Adapters_path%
copy %AzureIoTSDKs_path%c-utility\inc\azure_c_shared_utility %SharedUtility_path%
copy %AzureIoTSDKs_path%c-utility\src\ %SharedUtility_path%
copy /y %Arduino_pal_path%\azure_c_shared_utility\*.* %SharedUtility_path%

copy %AzureIoTSDKs_path%c-utility\pal\agenttime.c %Adapters_path%
copy %AzureIoTSDKs_path%c-utility\pal\tickcounter.c %Adapters_path%

rem // Copy the Arduino-specific files from the Arduino PAL path
copy %Arduino_pal_path%inc\*.* %Adapters_path%
copy %Arduino_pal_path%src\*.* %Adapters_path%

mkdir %AzureUHTTP_path%
copy %AzureIoTSDKs_path%c-utility\adapters\httpapi_compact.c %AzureUHTTP_path%

mkdir %AzureUMQTT_path%
copy %AzureIoTSDKs_path%umqtt\src %AzureUMQTT_path%
mkdir %AzureIoTHub_path%src\azure_umqtt_c\
copy %AzureIoTSDKs_path%umqtt\inc\azure_umqtt_c %AzureIoTHub_path%src\azure_umqtt_c\

del %sdk_path%*amqp*.*
del %sdk_path%iothubtransportmqtt_websockets.*

del %SharedUtility_path%tlsio_*.*
del %SharedUtility_path%wsio*.*
del %SharedUtility_path%x509_*.*
del %SharedUtility_path%etw*.*

popd
