# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param([string]$oldDir, [string]$newDir)

$ErrorActionPreference = "Stop"

try {
Set-Variable oldFile "$oldDir\library.properties"
Set-Variable newFile "$newDir\library.properties"

Get-Content $oldFile | Foreach-Object{
   $var = $_.Split('=')
   New-Variable -Name $var[0] -Value $var[1]
}

# Increment the 3rd part of the version
$newVersion = ($version).Split(".")
$newVersion[2] = [int]$newVersion[2] + 1
$newVersion = $newVersion -join "."

Get-Content $newFile | 
 % { $_ -creplace "version.+", "version=$newVersion" }  -OutVariable content | Out-Null
 
$content | Set-Content $newFile

# Commit changes to git and set a tag
Push-Location -Path $newDir
git add .
git commit -m "Sync Arduino libraries with latest Azure IoT SDK $newVersion"
git tag v$newVersion -m "Add tag v$newVersion"
Pop-Location
}

catch {
    echo "Failed to bump version for $newFile  $PSItem"
    exit 1
}
