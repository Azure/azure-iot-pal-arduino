@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@echo off
@setlocal EnableExtensions EnableDelayedExpansion

REM This script is not designed to be used directly. It's a client of release_prep.cmd
REM Parameter 1 is the workspace directory. Parameter 2 is the repo name.
echo ...
set repo_dir=%1\%2

git clone https://github.com/Azure-Samples/%2.git %repo_dir%

REM The particulars of the various devices and the SSID and password are environment variables
if [%2]==[iot-hub-c-huzzah-getstartedkit] (
    set dev_id=%ARDUINO_HUZZAH_ID%
    set dev_key=%ARDUINO_HUZZAH_KEY%
    set huzzah_file=%repo_dir%\remote_monitoring\remote_monitoring.c
    echo Editing !huzzah_file! to add heap check
    pushd !scripts_path!
    PowerShell.exe -ExecutionPolicy Bypass -Command "& './edit_huzzah.ps1 ' -file '!huzzah_file!'"
    popd
    if !ERRORLEVEL! NEQ 0 (
        echo Failed to edit huzzah sample: !huzzah_file!
        exit /b 1
    )
) else if [%2]==[iot-hub-c-m0wifi-getstartedkit] (
    set dev_id=%ARDUINO_M0_ID%
    set dev_key=%ARDUINO_M0_KEY%
) else (
    set dev_id=%ARDUINO_SPARK_ID%
    set dev_key=%ARDUINO_SPARK_KEY%
)

echo Editing iot_configs.h for %2
pushd !scripts_path!
set iotconfigs=%repo_dir%\remote_monitoring\iot_configs.h
PowerShell.exe -ExecutionPolicy Bypass -Command "& './edit_sample.ps1 ' -file '!iotconfigs!' -ssid '%ARDUINO_WIFI_SSID%' -password '%ARDUINO_WIFI_PASSWORD%' -hostname '!ARDUINO_HOST_NAME!' -id '!dev_id!' -key '!dev_key!'"
set iotconfigs=%repo_dir%\device_twin\iot_configs.h
PowerShell.exe -ExecutionPolicy Bypass -Command "& './edit_sample.ps1 ' -file '!iotconfigs!' -ssid '%ARDUINO_WIFI_SSID%' -password '%ARDUINO_WIFI_PASSWORD%' -hostname '!ARDUINO_HOST_NAME!' -id '!dev_id!' -key '!dev_key!'"
popd
