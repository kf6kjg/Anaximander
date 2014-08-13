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
echo Gathering libraries, if any...

if NOT EXIST curl.zip (
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'http://downloads.dlang.org/other/curl-7.28.1-devel-rainer.win64.zip', '.\curl.zip')"
	set needsextract=1
) else if NOT EXIST ..\libcurl.dll (
	if EXIST libcurl.dll (
		copy libcurl.dll ..\libcurl.dll
	) else (
		msg "%username%" It seems you have not extracted the curl zip file correctly.  Please make sure libcurl.dll is placed in this folder.
		exit /B
	)
)

if NOT EXIST mysql-native.zip (
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'https://github.com/rejectedsoftware/mysql-native/archive/v0.0.15.zip', '.\mysql-native.zip')"
	set needsextract=1
) else if NOT EXIST mysql (
	mkdir mysql
	copy mysql-native-0.0.15\source\mysql\* mysql
)

rem Requirement for DMagick
if NOT EXIST ImageMagick.zip (
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'http://www.imagemagick.org/download/windows/ImageMagick-windows.zip', '.\ImageMagick.zip')"
	set needsextract=1
) else (
	cd ImageMagick-*
	if NOT EXIST VisualMagick\bin\CORE_RL_magick_.dll (
		start VisualMagick\configure\configure.sln
		
		start Install-windows.txt
		
		msg "%username%" Please configure and compile ImageMagick using 64bit Dynamic Multithreaded default settings.
		
		cd ..
		exit /B
	) else (
		if NOT EXIST ..\..\CORE_RL_magick_.dll (
			copy VisualMagick\bin\CORE_RL_magick_.dll ..\..
			copy VisualMagick\lib\CORE_RL_magick_.lib ..
			
			rem Keep these sorted!
			copy VisualMagick\bin\CORE_RL_bzlib_.dll ..\..
			copy VisualMagick\bin\CORE_RL_glib_.dll ..\..
			copy VisualMagick\bin\CORE_RL_lcms_.dll ..\..
			copy VisualMagick\bin\CORE_RL_lqr_.dll ..\..
			copy VisualMagick\bin\CORE_RL_ttf_.dll ..\..
			copy VisualMagick\bin\CORE_RL_zlib_.dll ..\..
		)
	)
	cd ..
)

if NOT EXIST DMagick.zip (
	powershell.exe "(new-object System.Net.WebClient).DownloadFile( 'https://github.com/MikeWey/DMagick/archive/ImageMagick_6.8.9.zip', '.\DMagick.zip')"
	set needsextract=1
) else if NOT EXIST DMagick.lib (
	cd DMagick-ImageMagick_6.8.9
	
	rem implib is only needed for 32bit DLLs...  In this case we are 64bit all the way.
	
	make -f windows.mak
	
	if EXIST DMagick.lib (
		echo Please ignore the above error regarding implib...
		copy DMagick.lib ..
	) else (
		cd ..
		exit /B
	)
	
	mkdir ..\dmagick
	xcopy /E dmagick ..\dmagick
	
	cd ..
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
	exit /B
)

rem Compile the program
echo Generating docs and compiling...
rdmd -w -od. --build-only -m64 -Dddoc -cov -unittest -Ilib lib\CORE_RL_magick_.lib lib\curl.lib src\anaximander.d
