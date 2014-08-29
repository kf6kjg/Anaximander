@ECHO OFF

rem Only runs on Win7 or newer due to powershell dependency.


rem Get the version number
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set version=%%j
set version=%version:~0,4%%version:~4,2%%version:~6,2%%version:~8,2%


set package_name="anaximander-%version%-win64"

set package_dir="%package_name%"


rem Prep.
if EXIST "%package_dir%" (
	del /S /Q "%package_dir%"
)
mkdir "%package_dir%"

rem Get the binaries and DLLs
mkdir "%package_dir%\bin"
xcopy /E "bin" "%package_dir%\bin"
copy "%PROGRAMFILES(x86)%\Microsoft Visual Studio 10.0\VC\redist\x64\Microsoft.VC100.CRT\msvcr100.dll" "%package_dir%\bin"
copy "%PROGRAMFILES(x86)%\Microsoft Visual Studio 10.0\VC\redist\x64\Microsoft.VC100.OpenMP\vcomp100.dll" "%package_dir%\bin"


rem Get the config data
mkdir "%package_dir%\etc"
xcopy /E "etc" "%package_dir%\etc"

rem Get the script
copy anaximander.bat "%package_dir%"


rem Tell the user to package the whole shooting match.
explorer.exe "%package_dir%\.."
msg %username% "Please pack the %package_dir% folder into a zip archive and upload."
