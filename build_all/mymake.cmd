set NEWLOC=%USERPROFILE%\Documents\Arduino\libraries_staging

for /d %%G in ("%NEWLOC%\*") do rd /s /q "%%~G"

rd %NEWLOC%
tree %NEWLOC%

call make_sdk %NEWLOC%

dir %NEWLOC%