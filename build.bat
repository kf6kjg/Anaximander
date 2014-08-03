@ECHO OFF

rem Assumes you have dmd installed and in your $PATH. If not, go get it: http://dlang.org/dmd-windows.html
rem Only runs on Win7 or newer due to powershell dependency.


rem Get the version number
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set version=%%j
set version=%version:~0,4%%version:~4,2%%version:~6,2%%version:~8,2%

rem Process the version module to add the results into the source tree.
powershell.exe "(Get-Content src/aversioninfo.d.in) | ForEach-Object { $_ -replace '@VERSION@', '%version%' } | Set-Content src/aversioninfo.d"

rem Download the libraries and then complain to the user to extract them into the lib directory.
set needsextract=0
if NOT EXIST lib mkdir lib
cd lib

rem if NOT EXIST FILE.zip (
rem 	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'http://SITE/FILE.zip', '.\FILE.zip')"
rem 	set needsextract=1
rem )

cd ..
if %needsextract%==1 (
	explorer.exe lib
	msg "%username%" Please extract the zip files here.
)

rem Compile the program
rem  Keep files in shell listing (alphanumerical) order
dmd -m64 -Dddoc -odobj -cov -unittest -inline -w ^
	src/anaximander.d ^
	src/atilegrabber.d ^
	src/atilezoomer.d ^
	src/aversioninfo.d ^
