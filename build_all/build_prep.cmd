@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@setlocal EnableExtensions EnableDelayedExpansion
@echo off

call set_build_vars.cmd
if !ERRORLEVEL! NEQ 0 (
    echo Failed to set build vars
    exit /b 1
)

rem -----------------------------------------------------------------------------
rem -- ensure environment variables for sample editing
rem -----------------------------------------------------------------------------
call :ensure_environment ARDUINO_WIFI_SSID
call :ensure_environment ARDUINO_WIFI_PASSWORD
call :ensure_environment ARDUINO_HOST_NAME
call :ensure_environment ARDUINO_HUZZAH_ID
call :ensure_environment ARDUINO_M0_ID
call :ensure_environment ARDUINO_SPARK_ID
call :ensure_environment ARDUINO_HUZZAH_KEY
call :ensure_environment ARDUINO_M0_KEY
call :ensure_environment ARDUINO_SPARK_KEY
if !environment_ok! EQU "bad" (
    exit /b 1
)

rem -----------------------------------------------------------------------------
rem -- download arduino packages
rem -----------------------------------------------------------------------------
rem -----------------------------------------------------------------------------
rem -- download arduino compiler
rem -----------------------------------------------------------------------------
rem // The packages and compiler are no longer maintained in the cloud, and
rem // instead are just kept on the Arduino release machine. See the Arduino 
rem // release instructions for more info.

rem -----------------------------------------------------------------------------
rem -- create test directories
rem -----------------------------------------------------------------------------
call ensure_delete_directory.cmd %work_root%
if !ERRORLEVEL! NEQ 0 (
    exit /b 1
)
mkdir %work_root%
rem -- keep mkdir quiet when work_root == kits_root
mkdir %kits_root% >nul 2>&1

rem // Download all of the samples from the kits, and modify them for release testing
pushd %kits_root%
call %scripts_path%\get_sample.cmd %kits_root% iot-hub-c-huzzah-getstartedkit || exit /b 1
call %scripts_path%\get_sample.cmd %kits_root% iot-hub-c-m0wifi-getstartedkit || exit /b 1
call %scripts_path%\get_sample.cmd %kits_root% iot-hub-c-thingdev-getstartedkit || exit /b 1
popd

rem -----------------------------------------------------------------------------
rem -- build the Azure Arduino libraries in the user_libraries_path
rem -- wipe the user_libraries_path and re-create it
rem -----------------------------------------------------------------------------
call ensure_delete_directory.cmd %user_libraries_path%
if !ERRORLEVEL! NEQ 0 (
    echo Failed to delete directory: %user_libraries_path%
    exit /b 1
)
call make_sdk.cmd %user_libraries_path%
if !ERRORLEVEL! NEQ 0 (
    echo Failed to make sdk in %user_libraries_path%
    exit /b 1
)

rem -----------------------------------------------------------------------------
rem -- Fix source files that contain '%zu' or '%zd', which Arduino can't do
rem -----------------------------------------------------------------------------
PowerShell.exe -ExecutionPolicy Bypass -Command "& './fix_format_strings.ps1 ' '%user_libraries_path%'"
if !ERRORLEVEL! NEQ 0 (
    echo Failed to fix format strings
    exit /b 1
) else (
    echo Format strings fixed
)

rem -----------------------------------------------------------------------------
rem -- Generate the README.md files for the Arduino libraries
rem -----------------------------------------------------------------------------
PowerShell.exe -ExecutionPolicy Bypass -Command "& './README_builder.ps1 ' '%user_libraries_path%'"
if !ERRORLEVEL! NEQ 0 (
    echo Failed to generate readmes
    exit /b 1
) else (
    echo Generated readmes
)

rem -----------------------------------------------------------------------------
rem -- Copy the samples from the kits into the Arduino libraries
rem -----------------------------------------------------------------------------
xcopy %kits_root%\iot-hub-c-huzzah-getstartedkit\simplesample_http %user_libraries_path%\AzureIoTHub\examples\esp8266\simplesample_http /I
xcopy %kits_root%\iot-hub-c-huzzah-getstartedkit\simplesample_mqtt %user_libraries_path%\AzureIoTProtocol_MQTT\examples\esp8266\simplesample_mqtt /I
xcopy %kits_root%\iot-hub-c-huzzah-getstartedkit\simplesample_http %user_libraries_path%\AzureIoTProtocol_HTTP\examples\esp8266\simplesample_http /I
xcopy %kits_root%\iot-hub-c-huzzah-getstartedkit\simplesample_http %user_libraries_path%\AzureIoTUtility\examples\esp8266\simplesample_http /I
xcopy %kits_root%\iot-hub-c-m0wifi-getstartedkit\simplesample_http %user_libraries_path%\AzureIoTHub\examples\samd\simplesample_http /I
xcopy %kits_root%\iot-hub-c-m0wifi-getstartedkit\simplesample_mqtt %user_libraries_path%\AzureIoTProtocol_MQTT\examples\samd\simplesample_mqtt /I
xcopy %kits_root%\iot-hub-c-m0wifi-getstartedkit\simplesample_http %user_libraries_path%\AzureIoTProtocol_HTTP\examples\samd\simplesample_http /I
xcopy %kits_root%\iot-hub-c-m0wifi-getstartedkit\simplesample_http %user_libraries_path%\AzureIoTUtility\examples\samd\simplesample_http /I

rem -----------------------------------------------------------------------------
rem -- download arduino libraries into user_libraries_path
rem -----------------------------------------------------------------------------
mkdir %user_libraries_path%
pushd %user_libraries_path%
git clone https://github.com/adafruit/Adafruit_Sensor
git clone https://github.com/adafruit/Adafruit_DHT_Unified
git clone https://github.com/adafruit/DHT-sensor-library
git clone https://github.com/adafruit/Adafruit_BME280_Library
git clone https://github.com/arduino-libraries/WiFi101
git clone https://github.com/arduino-libraries/RTCZero

rem -----------------------------------------------------------------------------
rem -- convert the Azure Arduino libraries in the user_libraries_path into
rem -- their respective git repos. This is equivalent to a clone followed
rem -- by updating the library contents, but avoids putting robocopy warnings
rem -- into the output.
rem -----------------------------------------------------------------------------

rem -- clone the Azure arduino libraries into temp directories
git clone https://github.com/Azure/azure-iot-arduino AzureIoTHub_temp
git clone https://github.com/Azure/azure-iot-arduino-protocol-mqtt AzureIoTProtocol_MQTT_temp
git clone https://github.com/Azure/azure-iot-arduino-protocol-http AzureIoTProtocol_HTTP_temp
git clone https://github.com/Azure/azure-iot-arduino-utility AzureIoTUtility_temp

rem -- turn the built libraries into proper git repos by giving them their .git folders
call :relocate_git_folders AzureIoTHub
if !ERRORLEVEL! NEQ 0 (
    popd
    exit /b 1
)
call :relocate_git_folders AzureIoTProtocol_MQTT
if !ERRORLEVEL! NEQ 0 (
    popd
    exit /b 1
)
call :relocate_git_folders AzureIoTProtocol_HTTP
if !ERRORLEVEL! NEQ 0 (
    popd
    exit /b 1
)
call :relocate_git_folders AzureIoTUtility
if !ERRORLEVEL! NEQ 0 (
    popd
    exit /b 1
)
popd



exit /b 0

rem -----------------------------------------------------------------------------
rem -- Put the .git folders from the temp repos into the actual Arduino 
rem -- library folders and delete the temp repo. The clone is not done in
rem -- this routine because moving the file too soon after the clone can
rem -- provoke access denied errors.
rem
rem -- Also bump the versions in the new libraries
rem -----------------------------------------------------------------------------
:relocate_git_folders
attrib -h %1_temp\.git
move %1_temp\.git %1\.git
attrib +h %1\.git
pushd !scripts_path!
PowerShell.exe -ExecutionPolicy Bypass -Command "& './bump_version.ps1 ' -oldDir '%user_libraries_path%\%1_temp' -newDir '%user_libraries_path%\%1'"
if !ERRORLEVEL! NEQ 0 (
    echo Failed to bump version in %1
    popd
    exit /b 1
) else (
    echo Bumped version in %1
)
popd
rd /s /q %1_temp
exit /b 0

rem -- Make sure this variable is defined
:ensure_environment
if "!%1!"=="" (
    echo Error: %1 is not defined
    set environment_ok="bad"
)
exit /b

