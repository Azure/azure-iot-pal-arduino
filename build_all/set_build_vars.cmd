@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@echo off

set scripts_path=%~dp0
rem // remove trailing slash
set scripts_path=%scripts_path:~0,-1%

set jenkins_workspace=%scripts_path%\..\..
rem // resolve to fully qualified path
for %%i in ("%jenkins_workspace%") do set jenkins_workspace=%%~fi

set arduino_esp8266_version=2.4.0
set adafruit_samd_version=1.0.21
set arduino_samd_version=1.6.17
set arduino_builder_version=1.8.5
set esptool_version=0.4.13

set work_root=%jenkins_workspace%\arduino_work
set kits_root=%jenkins_workspace%\arduino_work
set tools_root=%jenkins_workspace%\arduino_tools
set tools_root=%jenkins_workspace%\arduino_tools
set built_binaries_root=%jenkins_workspace%\arduino_work\bin

set tests_list_file=tests.lst
set compiler_path=%jenkins_workspace%\arduino_tools\arduino-%arduino_builder_version%

set compiler_hardware_path=%compiler_path%\hardware
set compiler_tools_builder_path=%compiler_path%\tools-builder
set compiler_tools_processor_path=%compiler_path%\hardware\tools\avr

set compiler_libraries_path=%compiler_path%\libraries
set compiler_packages_path=%jenkins_workspace%\arduino_tools\packages

rem -----------------------------------------------------------------------------
rem -- Libraries get built and used from c:\jenkins\workspace\arduino_work
rem -----------------------------------------------------------------------------
set user_libraries_path=%work_root%\libraries


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
echo Setup environment for Arduino with the following parameters:
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
echo   compiler_packages_path        = %compiler_packages_path%
echo.
echo   user_libraries_path = %user_libraries_path%
echo.
echo   arduino_esp8266_version = %arduino_esp8266_version%
echo   adafruit_samd_version = %adafruit_samd_version%
echo   arduino_samd_version = %arduino_samd_version%
echo   arduino_builder_version = %arduino_builder_version%
echo   esptool_version = %esptool_version%
echo.
echo.
