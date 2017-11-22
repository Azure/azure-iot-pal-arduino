# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

# This script checks .c files for '%zu' and '%zd' in format strings and
# replaces them with '%u', which the Arduino compilers can understand
param(
    [Parameter(Position = 0)][string]$libsDir
)

if ($libsDir -eq '') {
    echo "README_builder.ps1 needs a single positional target path parameter"
    exit 1
}

# The locations of .c files that need to be checked for 
$d1 = "$libsDir\AzureIoTHub\src\sdk"
$d2 = "$libsDir\AzureIoTProtocol_HTTP\src\azure_uhttp_c"
$d3 = "$libsDir\AzureIoTProtocol_MQTT\src\azure_umqtt_c"
$d4 = "$libsDir\AzureIoTUtility\src\azure_c_shared_utility"

function Fix-File
{
    param([Parameter(Position = 0)][string]$target_file)
    echo $target_file
    # Edit the sample iot_configs.h to have proper WiFi and subscription info
    Get-Content $target_file | Out-String |
     % { $_ -creplace "%zu", "%u" } |
     % { $_ -creplace "%zd", "%u" }  -OutVariable content | Out-Null
 
    $content | Set-Content $target_file

}


function Fix-Dir
{
    param([Parameter(Position = 0)][string]$target_dir)
    echo "$target_dir"
    get-childitem $target_dir -recurse   | where {$_.extension -eq ".c"} | % {
        Fix-File $_.FullName 
    }
}

Fix-Dir $d1
Fix-Dir $d2
Fix-Dir $d3
Fix-Dir $d4
