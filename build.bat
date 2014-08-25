@ECHO OFF

rem Assumes you have dmd installed and in your $PATH. If not, go get it: http://dlang.org/dmd-windows.html
rem Only runs on Win7 or newer due to powershell dependency.


rem Get the version number
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set version=%%j
set version=%version:~0,4%%version:~4,2%%version:~6,2%%version:~8,2%

rem Process the version module to add the results into the source tree.
powershell.exe "(Get-Content src/aversioninfo.d.in) | ForEach-Object { $_ -replace '@VERSION@', '%version%' } | Set-Content src/aversioninfo.d"

rem Create the needed folders
if NOT EXIST bin mkdir bin
if NOT EXIST imports mkdir imports
if NOT EXIST lib mkdir lib

rem Download the libraries and then complain to the user to extract them into the lib directory.
set needsextract=0
cd lib
echo Gathering libraries, if any...

if NOT EXIST curl.zip (
	echo * Downloading curl library...
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'http://downloads.dlang.org/other/curl-7.28.1-devel-rainer.win64.zip', '.\curl.zip')"
	set needsextract=1
) else if NOT EXIST ..\bin\libcurl.dll (
	if EXIST libcurl.dll (
		echo * Gathering libcurl DLL to binary folder...
		copy libcurl.dll ..\bin\libcurl.dll
	) else (
		msg "%username%" It seems you have not extracted the curl zip file correctly.  Please make sure libcurl.dll is placed in this folder.
		exit /B
	)
)

if NOT EXIST mysql-native.zip (
	echo * Downloading mysql library...
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'https://github.com/rejectedsoftware/mysql-native/archive/v0.0.15.zip', '.\mysql-native.zip')"
	set needsextract=1
) else if NOT EXIST ..\imports\mysql (
	echo * Gathering mysql library to imports folder...
	mkdir ..\imports\mysql
	xcopy /E mysql-native-0.0.15\source\mysql ..\imports\mysql
)

rem Requirement for DMagick
if NOT EXIST ImageMagick.zip (
	echo * Downloading ImageMagick library...
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'http://www.imagemagick.org/download/windows/ImageMagick-windows.zip', '.\ImageMagick.zip')"
	set needsextract=1
) else (
	cd ImageMagick-*
	if NOT EXIST VisualMagick\bin\CORE_RL_magick_.dll (
		echo * Please configure and compile ImageMagick using Release mode 64bit Dynamic Multithreaded default settings.
		start VisualMagick\configure\configure.sln
		
		start Install-windows.txt
		
		msg "%username%" Please configure and compile ImageMagick using Release mode 64bit Dynamic Multithreaded default settings.
		
		echo * When done compiling, please execute the build command again!
		cd ..\..
		exit /B
	) else (
		if NOT EXIST ..\..\bin\CORE_RL_magick_.dll (
			echo * Gathering ImageMagick DLLs to binary folder...
			copy VisualMagick\bin\*.dll ..\..\bin
			echo * Gathering ImageMagick lib file to library folder...
			copy VisualMagick\lib\CORE_RL_magick_.lib ..
		)
	)
	cd ..
)

if NOT EXIST DMagick.zip (
	echo * Downloading DMagick library...
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'https://github.com/kf6kjg/DMagick/archive/master.zip', '.\DMagick.zip')"
	set needsextract=1
) else if NOT EXIST ..\imports\dmagick (
	echo * Gathering DMagick library to imports folder...
	mkdir ..\imports\dmagick
	xcopy /E DMagick-master\dmagick ..\imports\dmagick
)


rem if NOT EXIST FILE.zip (
rem 	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'http://SITE/FILE.zip', '.\FILE.zip')"
rem 	set needsextract=1
rem )

cd ..
if %needsextract%==1 (
	echo Requesting user to extract libraries...
	explorer.exe lib
	msg "%username%" Please extract the zip files here.
	echo * When done extracting, please execute the build command again!
	exit /B
)

rem Compile the program
echo Generating docs and compiling...
rdmd -w -odbin --build-only -m64 -Dddoc -cov -unittest -version=DMagick_No_Display -Iimports lib\CORE_RL_magick_.lib lib\curl.lib src\anaximander.d


rem Create execution script
echo "* Creating batch file for execution: ./anaximander.bat"
echo @ECHO OFF > anaximander.bat
echo bin\anaximander %%* >> anaximander.bat

echo * To run anaximander:
echo     ./anaximander.bat
