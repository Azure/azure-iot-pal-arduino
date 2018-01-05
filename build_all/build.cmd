@REM Copyright (c) Microsoft. All rights reserved.
@REM Licensed under the MIT license. See LICENSE file in the project root for full license information.

@setlocal EnableExtensions EnableDelayedExpansion
@echo off

call set_build_vars.cmd %*
if !ERRORLEVEL! NEQ 0 (
    echo Failed to set build vars
    exit /b 1
)

rem -----------------------------------------------------------------------------
rem -- Execute all tests
rem -----------------------------------------------------------------------------

call :ExecuteAllTests

set finalResult=0

if %build_test%==ON (
    echo.
    echo.
    echo Build results:

    for /F "tokens=2* delims=.=" %%A in ('set __errolevel_build.') do (
        @echo Build %%A %%B
        if "%%B"=="FAILED" (
            set finalResult=1
        )
    )
)

if %run_test%==ON (
    echo.
    echo.
    echo Execution results:

    for /F "tokens=2* delims=.=" %%A in ('set __errolevel_run.') do (
        @echo Run %%A %%B
        if "%%B"=="FAILED" (
            set finalResult=1
        )
    )
)

echo.
if !finalResult!==0 (
   echo TEST SUCCEED
) else (
   echo TEST FAILED
)

exit /b !finalResult!


rem -----------------------------------------------------------------------------
rem -- subroutines
rem -----------------------------------------------------------------------------

:usage
echo build.cmd [options]
echo options:
echo  -b, --build-only          only build the project (default)
echo  -r, --run-only            only run the test
echo  -e2e, --run-e2e-tests     run end-to-end test
echo  -t, --tests <test_list>   determine the file with the test list
goto :eof


rem -----------------------------------------------------------------------------
rem -- helper subroutines
rem -----------------------------------------------------------------------------

REM Parser tests.lst
:ExecuteAllTests
set testName=false
set projectName=
set SourcePath="******* SourcePath not set ********"

for /F "tokens=*" %%F in (%tests_list_file%) do (
    if /i "%%F"=="" (
        REM ignore empty line.
    ) else ( 
        set command=%%F
        if /i "!command:~0,1!"=="#" (
            echo Comment=!command:~1!
        ) else ( if /i "!command:~0,1!"=="[" (
            if %build_test%==ON (
                call :BuildTest
            )
            if %run_test%==ON (
                call :RunTest
            )
            set projectName=!command:~1,-1!
            if /i "!projectName!"=="End" goto :eof
        ) else (
            for /f "tokens=1 delims==" %%A in ("!command!") do set key=%%A
            call set value=%%command:!key!=%%
            set value=!value:~1!
            set !key!=!value!
        ) ) ) 
    ) 
)
goto :eof


REM Build each test in the Tests.lst
:BuildTest
if not "!projectName!"=="" (
    echo.
    echo Build !projectName!
    echo   test_root=%test_root%
    echo   work_root=%work_root%
    echo   Target=!Target!
    echo   RelativePath=!RelativePath!
    echo   RelativeWorkingDir=!RelativeWorkingDir!
    echo   SerialPort=!SerialPort!
    echo   MaxAllowedDurationSeconds=!MaxAllowedDurationSeconds!
    echo   CloneURL=!CloneURL!
    echo   Categories=!Categories!
    echo   Hardware=!Hardware!
    echo   CPUParameters=!CPUParameters!
    echo   Build=!Build!

    if "!Build!"=="Disable" (
        set __errolevel_build.!projectName!=DISABLED
        echo ** Build for !projectName! is disable. **
        goto :eof
    )
            
    mkdir %built_binaries_root%!RelativeWorkingDir!

rem Step 1, build dump preferences:
rem Ex: arduino-builder 
rem                        -dump-prefs 
rem                     -logger=machine 
rem                     -hardware "C:\Program Files (x86)\Arduino\hardware" 
rem                     -hardware "C:\Users\iottestuser\AppData\Local\Arduino15\packages" 
rem                     -hardware "C:\Users\iottestuser\Documents\Arduino\hardware" 
rem                     -tools "C:\Program Files (x86)\Arduino\tools-builder" 
rem                     -tools "C:\Program Files (x86)\Arduino\hardware\tools\avr" 
rem                     -tools "C:\Users\iottestuser\AppData\Local\Arduino15\packages" 
rem                     -built-in-libraries "C:\Program Files (x86)\Arduino\libraries" 
rem                     -libraries "C:\Users\iottestuser\Documents\Arduino\libraries" 
rem                     -fqbn=esp8266:esp8266:huzzah:CpuFrequency=80,UploadSpeed=115200,FlashSize=4M3M 
rem                     -ide-version=10609 
rem                     -build-path "C:\Users\iottestuser\AppData\Local\Temp\build505ec6e3f4000475ae6da076f93e5ffe.tmp" 
rem                     -warnings=none 
rem                     -prefs=build.warn_data_percentage=75 
rem                     -verbose 
rem                     "F:\Azure\IoT\SDKs\iot-hub-c-huzzah-getstartedkit-master\remote_monitoring\remote_monitoring.ino"
rem
rem Step 2, compile the project:
rem Ex: arduino-builder  
rem                     -compile  
rem                     -logger=machine  
rem                     -hardware "C:\Program Files (x86)\Arduino\hardware"  
rem                     -hardware "C:\Users\iottestuser\AppData\Local\Arduino15\packages"  
rem                     -hardware "C:\Users\iottestuser\Documents\Arduino\hardware"  
rem                     -tools "C:\Program Files (x86)\Arduino\tools-builder"  
rem                     -tools "C:\Program Files (x86)\Arduino\hardware\tools\avr"  
rem                     -tools "C:\Users\iottestuser\AppData\Local\Arduino15\packages"  
rem                     -built-in-libraries "C:\Program Files (x86)\Arduino\libraries"  
rem                     -libraries "C:\Users\iottestuser\Documents\Arduino\libraries"  
rem                     -fqbn=esp8266:esp8266:huzzah:CpuFrequency=80,UploadSpeed=115200,FlashSize=4M3M  
rem                     -ide-version=10609  
rem                     -build-path "C:\Users\iottestuser\AppData\Local\Temp\build505ec6e3f4000475ae6da076f93e5ffe.tmp"  
rem                     -warnings=none  
rem                     -prefs=build.warn_data_percentage=75  
rem                     -verbose  
rem                     "F:\Azure\IoT\SDKs\iot-hub-c-huzzah-getstartedkit-master\remote_monitoring\remote_monitoring.ino"

    set compiler_name=%compiler_path%\arduino-builder.exe

    set hardware_parameters=-hardware "%compiler_hardware_path%" -hardware "%compiler_packages_path%"
    set tools_parameters=-tools "%compiler_tools_builder_path%" -tools "%compiler_tools_processor_path%" -tools "%compiler_packages_path%"
    set libraries_parameters=-built-in-libraries "%compiler_libraries_path%" -libraries "%user_libraries_path%"
    set parameters=-logger=machine !hardware_parameters! !tools_parameters! !libraries_parameters! !CPUParameters! -build-path "%built_binaries_root%!RelativeWorkingDir!" -warnings=none -prefs=build.warn_data_percentage=75 -verbose !SourcePath!\!Target!

    echo Dump Arduino preferences:
    echo  !compiler_name! -dump-prefs !parameters!
    call !compiler_name! -dump-prefs !parameters!
    
    echo.
    echo Building: !RelativePath!
    echo.    Compiler: !compiler_name! 
    echo.    -compile !parameters!
    call !compiler_name! -compile !parameters!

    if "!errorlevel!"=="0" (
        set __errolevel_build.!projectName!=SUCCEED
    ) else (
        set __errolevel_build.!projectName!=FAILED
    )
)
set SourcePath="******* SourcePath not set ********"
goto :eof


REM Run each test in the Tests.lst
:RunTest
if not "!projectName!"=="" (
    echo.
    echo Run !projectName!
    echo   Target=!Target!
    echo   RelativeWorkingDir=!RelativeWorkingDir!
    echo   LogLines=!LogLines!
    echo   MinimumHeap=!MinimumHeap!
    echo   Execution=!Execution!

    if "!Execution!"=="Disable" (
        set __errolevel_run.!projectName!=DISABLED
        echo ** Execution for !projectName! is disable. **
        goto :eof
    )
    
    call powershell.exe -NoProfile -NonInteractive -ExecutionPolicy unrestricted -Command .\execute.ps1 -binaryPath:%built_binaries_root%!RelativeWorkingDir!\!Target!.bin -serialPort:!SerialPort! -esptool:%compiler_packages_path%\esp8266\tools\esptool\%esptool_version%\esptool.exe -logLines:!LogLines! -minimumHeap:!MinimumHeap!

    if "!errorlevel!"=="0" (
        set __errolevel_run.!projectName!=SUCCEED
    ) else (
        set __errolevel_run.!projectName!=FAILED
    )

)
goto :eof
