# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param([string]$file,
 [string]$ssid,
 [string]$password,
 [string]$hostname,
 [string]$id,
 [string]$key)

$ErrorActionPreference = "Stop"

# Ignore non-existent files
if (Test-Path $file -PathType Leaf)
{
    # Edit the sample iot_configs.h to have proper WiFi and subscription info
    Get-Content $file |
     % { $_ -replace “<Your WiFi network SSID or name>”, $ssid } |
     % { $_ -replace “<Your WiFi network WPA password or WEP key>”, $password } |
     % { $_ -replace “<host_name>”, $hostname } |
     % { $_ -replace “<device_id>”, $id } |
     % { $_ -replace “<device_key>”, $key }  -OutVariable content | Out-Null
     
    $content | Set-Content $file
}

