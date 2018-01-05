# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param([string]$oldDir, [string]$newDir)

$ErrorActionPreference = "Stop"

try {
Set-Variable oldLibraryProperties "$oldDir\library.properties"
Set-Variable newLibraryProperties "$newDir\library.properties"
# The newDir directory name is the library name
Set-Variable libraryName $newDir.split("\")[-1]

Get-Content $oldLibraryProperties | Foreach-Object{
   $var = $_.Split('=')
   New-Variable -Name $var[0] -Value $var[1]
}

# Increment the 3rd part of the version
echo "Found old version: $version"
$newVersion = ($version).Split(".")
$newVersion[2] = [int]$newVersion[2] + 1
$newVersion = $newVersion -join "."
echo "New version: $newVersion"

# -------------------------------------------------------
# Update the library.properties file
# -------------------------------------------------------
Get-Content $newLibraryProperties | 
 % { $_ -creplace "version.+", "version=$newVersion" }  -OutVariable newLibraryPropertiesContent | Out-Null
 
$newLibraryPropertiesContent | Set-Content $newLibraryProperties

# -------------------------------------------------------
# Update the library header file
# -------------------------------------------------------
Set-Variable libraryHeaderFile "$newDir\src\$libraryName.h"
Set-Variable versionDefine ("#define " + $libraryName.replace('_','') + "Version `"$newVersion`"")

Get-Content $libraryHeaderFile | 
 % { $_ -creplace "#define AzureIoT.+", $versionDefine }  -OutVariable newLibraryHeaderContent | Out-Null
 
$newLibraryHeaderContent | Set-Content $libraryHeaderFile

# -------------------------------------------------------
# Commit changes to git and set a tag
# -------------------------------------------------------
Push-Location -Path $newDir
git add .
git commit -m "Sync Arduino libraries with latest Azure IoT SDK $newVersion"
git tag v$newVersion -m "Add tag v$newVersion"
$gitResult = $LastExitCode
if ($gitResult -ne 0) {
    throw gitResult
}
Pop-Location
}

catch {
    echo "Failed to bump version for $newLibraryProperties  $PSItem"
    exit 1
}
