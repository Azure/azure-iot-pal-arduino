# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param([string]$file)

$ErrorActionPreference = "Stop"

try {
$target = "void remote_monitoring_run\(void\)\r\n"

$memcheck = @"
// This function drops heap info into the output where execute.ps1 can check for too much heap consumption
static void do_memcheck(void)
{
    size_t current_heap_size;
    uint8_t* ptr = (uint8_t*)malloc(1024);
    free(ptr);
    current_heap_size = (size_t)(0x3FFFC000-(uint32_t)ptr);
    LogInfo("Heap:%d", current_heap_size);
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

