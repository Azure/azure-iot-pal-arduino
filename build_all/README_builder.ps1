# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param(
    [Parameter(Position = 0)][string]$libsDir
)

if ($libsDir -eq '') {
    echo "README_builder.ps1 needs a single positional target path parameter"
    exit 1
}


# -----------------------------------------------------------------
#    title_hub text
# -----------------------------------------------------------------
$title_hub =
@"
# AzureIoTHub - Azure IoT Hub library for Arduino

This library is a port of the 
[Microsoft Azure IoT device SDK for C](https://github.com/Azure/azure-iot-sdks/blob/master/c/readme.md)
 to Arduino. It allows you to use several Arduino compatible boards with Azure IoT Hub.
"@

# -----------------------------------------------------------------
#    title_hub text
# -----------------------------------------------------------------
$title_http =
@"
# AzureIoTProtocol_HTTP - Azure IoT HTTP protocol library for Arduino

This library is a port of the compact implementation of the HTTP protocol from
[Microsoft Azure IoT device SDK for C](https://github.com/Azure/azure-iot-sdks/blob/master/c/readme.md)
 to Arduino. Together with the AzureIoTHub, it allows you to use several Arduino compatible 
 boards with Azure IoT HTTP protocol.
"@

# -----------------------------------------------------------------
#    title_mqtt text
# -----------------------------------------------------------------
$title_mqtt =
@"
# AzureIoTProtocol_MQTT - Azure IoT MQTT protocol library for Arduino

This library is a port of the MQTT protocol from 
[Microsoft Azure IoT device SDK for C](https://github.com/Azure/azure-iot-sdks/blob/master/c/readme.md)
to Arduino. Together with the AzureIoTHub, it allows you to use several Arduino compatible 
boards with Azure IoT MQTT protocol.
"@

# -----------------------------------------------------------------
#    title_utility text
# -----------------------------------------------------------------
$title_utility =
@"
# AzureIoTUtility - Azure IoT Utility library for Arduino

This library is a port of the 
[Microsoft Azure C Shared Utility](https://github.com/Azure/azure-c-shared-utility/blob/master/c/readme.md) 
to Arduino. It allows you to use several Arduino compatible boards with Azure IoT Hub.
"@


# Build the readme.md's for the exported libraries of make_sdk.cmd
Get-Content README_template.md  | 
 % { $_ -replace “{{protocol_uc}}”,”HTTP” } |
 % { $_ -replace “{{protocol_lc}}”,”http” } |
 % { $_ -replace “{{title}}”,$title_hub }   |
Set-Content $libsDir/AzureIoTHub/README.md

Get-Content README_template.md  | 
 % { $_ -replace “{{protocol_uc}}”,”HTTP” } |
 % { $_ -replace “{{protocol_lc}}”,”http” } |
 % { $_ -replace “{{title}}”,$title_http }  |
Set-Content $libsDir/AzureIoTProtocol_HTTP/README.md

Get-Content README_template.md  | 
 % { $_ -replace “{{protocol_uc}}”,”MQTT” } |
 % { $_ -replace “{{protocol_lc}}”,”mqtt” } |
 % { $_ -replace “{{title}}”,$title_mqtt }  |
Set-Content $libsDir/AzureIoTProtocol_MQTT/README.md

Get-Content README_template.md  | 
 % { $_ -replace “{{protocol_uc}}”,”HTTP” } |
 % { $_ -replace “{{protocol_lc}}”,”http” } |
 % { $_ -replace “{{title}}”,$title_utility } |
Set-Content $libsDir/AzureIoTUtility/README.md

