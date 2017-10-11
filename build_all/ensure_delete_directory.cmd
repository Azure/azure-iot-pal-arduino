@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@setlocal EnableExtensions EnableDelayedExpansion
@echo off

rmdir %1 /s /q > nul 2>&1 || @rem
if !ERRORLEVEL! NEQ 0 (
    if !ERRORLEVEL! NEQ 2 (
        echo Failed to delete directory: %1
        exit /b 1
    )
)
exit /b 0
