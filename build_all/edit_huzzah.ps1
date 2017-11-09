# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param([string]$file)

$ErrorActionPreference = "Stop"

try {
$target = "void remote_monitoring_run\(void\)\r\n"

$memcheck = @"
// This function drops heap info into the output where execute.ps1 can check for too much heap consumption
#include <umm_malloc/umm_malloc.h>
static void do_memcheck()
{   
    size_t current_heap_size = umm_free_heap_size();
    LogInfo("Heap:%d", current_heap_size);
    return;
}


void remote_monitoring_run(void)

"@

$while_loop = "while\s*\(1\)\r\n\s*\{"

$while_loop_2 = @"
while(1)
                        {
                            do_memcheck();
"@


# Edit the sample iot_configs.h to have proper WiFi and subscription info
Get-Content $file | Out-String |
 % { $_ -replace $while_loop, $while_loop_2 } |
 % { $_ -creplace $target, $memcheck }  -OutVariable content | Out-Null
 
$content | Set-Content $file

}

catch {
    echo "Failure editing huzzah file"
    exit 1
}

