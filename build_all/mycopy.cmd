set DIR=%USERPROFILE%\Documents\Arduino
set NEWLOC=%DIR%\libraries_staging
set OLDLOC=%DIR%\libraries

for /d %%G in ("%OLDLOC%\AzureIoT*") do rd /s /q "%%~G"

xcopy %NEWLOC%\* %OLDLOC% /E
