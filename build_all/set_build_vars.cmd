@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@echo off

set scripts_path=%~dp0
rem // remove trailing slash
set scripts_path=%scripts_path:~0,-1%

set jenkins_workspace=%scripts_path%\..\..
rem // resolve to fully qualified path
for %%i in ("%jenkins_workspace%") do set jenkins_workspace=%%~fi

set work_root=%jenkins_workspace%\arduino_work
set kits_root=%jenkins_workspace%\arduino_work
set tools_root=%jenkins_workspace%\arduino_tools
set tools_root=%jenkins_workspace%\arduino_tools
set built_binaries_root=%jenkins_workspace%\arduino_work\bin
if not defined IOTHUB_ARDUINO_VERSION (
    echo Eror: IOTHUB_ARDUINO_VERSION is not defined
    exit /b 1
)
set tests_list_file=tests.lst
set compiler_path=%jenkins_workspace%\arduino_tools\%IOTHUB_ARDUINO_VERSION%

set compiler_hardware_path=%compiler_path%\hardware
set compiler_tools_builder_path=%compiler_path%\tools-builder
set compiler_tools_processor_path=%compiler_path%\hardware\tools\avr

set compiler_libraries_path=%compiler_path%\libraries
set user_packages_path=%jenkins_workspace%\arduino_tools\arduino15-2.3.0\packages

rem -----------------------------------------------------------------------------
rem -- If this computer runs the Arduino IDE, use the user's hardware path
rem -- and library path. Otherwise, keep stuff in the Jenkins directories.
rem -----------------------------------------------------------------------------

if exist "%UserProfile%\Documents\Arduino" (
    echo Arduino IDE directory detected
    set user_hardware_path=%UserProfile%\Documents\Arduino\hardware
    set user_libraries_path=%UserProfile%\Documents\Arduino\libraries
) else (
    set user_hardware_path=%tools_root%\hardware
    set user_libraries_path=%work_root%\libraries
    echo No Arduino IDE directory detected
)


rem -----------------------------------------------------------------------------
rem -- parse script arguments
rem -----------------------------------------------------------------------------
set build_test=ON
set run_test=OFF

:args_loop
if "%1" equ "" goto args_done
if "%1" equ "-b" goto arg_build_only
if "%1" equ "--build-only" goto arg_build_only
if "%1" equ "-r" goto arg_run_only
if "%1" equ "--run-only" goto arg_run_only
if "%1" equ "-e2e" goto arg_run_e2e_tests
if "%1" equ "--run-e2e-tests" goto arg_run_e2e_tests
if "%1" equ "--tests" goto arg_test_tests
if "%1" equ "-t" goto arg_test_tests
call :usage && exit /b 1

:arg_build_only
set build_test=ON
goto args_continue

:arg_run_only
set build_test=OFF
set run_test=ON
goto args_continue

:arg_run_e2e_tests
set build_test=ON
set run_test=ON
goto args_continue

:arg_test_tests
set tests_list_file=%2
shift
goto args_continue

:args_continue
shift
goto args_loop

:args_done

echo.
echo Setup environment for Arduino with the follow parameters:
echo.
echo   build_test  = %build_test%
echo   run_test    = %run_test%
echo   tests_list_file = %tests_list_file%
echo.
echo   scripts_path        = %scripts_path%
echo   jenkins_workspace   = %jenkins_workspace%
echo   work_root           = %work_root%
echo   kits_root           = %kits_root%
echo   built_binaries_root = %built_binaries_root%
echo.
echo   compiler_path                 = %compiler_path%
echo   compiler_hardware_path        = %compiler_hardware_path%
echo   compiler_tools_builder_path   = %compiler_tools_builder_path%
echo   compiler_tools_processor_path = %compiler_tools_processor_path%
echo   compiler_libraries_path       = %compiler_libraries_path%
echo   user_packages_path            = %user_packages_path%
echo.
echo   user_libraries_path = %user_libraries_path%
echo   user_hardware_path  = %user_hardware_path%
echo.
echo.

