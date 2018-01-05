@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@setlocal EnableExtensions EnableDelayedExpansion
@echo off

REM Ensure the existence of a git repo specified by %2, in a directory specified by
REM %1 at a release tag specified by %3. The repo directory name is equal to the release tag name.
REM Any sibling content will be assumed to be an old version, and will be deleted.

set container=%1
set repo=%2
set tag_name=%3

REM First just check for the existence of the tag-named directory. If it's there,
REM assume everything is okay.

if EXIST %container%\%tag_name% (
    echo Tag name %tag_name% for %repo% is present
    exit /b 0
)

REM Before cloning the repo, empty out the containing directory
pushd %container%
del *.* /S /Q >nul 2>&1
REM Deleting all the empty subdirs that were left behind
echo ***********************
for /d %%p in (%container%\*) do rmdir /S /Q "%%p"

REM Clone the repo into a temp directory (temp avoids problems if the process fails to do the checkout)
echo Cloning %repo% into %container% as %tag_name%
git clone %repo% temp
if !ERRORLEVEL! NEQ 0 (
echo Failed to clone %repo%
    popd
    exit /b 1
)
cd temp

REM Checkout the requested tag
echo Checking out the requested tag %tag_name%
git -c advice.detachedHead=false checkout %tag_name%
if !ERRORLEVEL! NEQ 0 (
echo Failed to checkout tag %tag_name%
    popd
    exit /b 1
)
cd ..

REM Rename the repo to be the tag name
rename temp %tag_name%

popd
