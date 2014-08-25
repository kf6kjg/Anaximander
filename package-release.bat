@ECHO OFF

rem Only runs on Win7 or newer due to powershell dependency.


rem Get the version number
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set version=%%j
set version=%version:~0,4%%version:~4,2%%version:~6,2%%version:~8,2%


set package_name="anaximander-%version%"

set package_dir="%package_name%"


rem Prep.
if EXIST "%package_dir%" (
	del /SY "%package_dir%"
)
mkdir "%package_dir%"

rem Get the binaries and DLLs
mkdir "%package_dir%\bin"
xcopy /E "bin" "%package_dir%\bin"

rem Get the config data
mkdir "%package_dir%\etc"
xcopy /E "etc" "%package_dir%\etc"


rem Tell the user to package the whole shooting match.
explorer.exe "%package_dir%\.."
msg %username% "Please pack the %package_dir% folder into a zip archive and upload."
