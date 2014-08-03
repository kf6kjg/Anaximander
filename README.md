Map tile generator for [InWorldz][] servers using compiled D and the [ImageMagick][] library.

[InWorldz]: http://inworldz.com/
[ImageMagick]: http://www.imagemagick.org/

# Building source #

## Microsoft Windows ##
Requires Windows 7 or newer due to dependency on Microsoft PowerShell 2 or newer. Requires [dmd][] to be on the PATH.
1. Clone repository (or download source archive)
2. Execute `build.bat` (preferably with the Command Prompt)
3. If a Windows Explorer window opens and a message pops up, follow the instructions then repeat step 2.
4. Test the resuling `anaximander.exe` with the Windows Command Prompt.

[dmd]: http://dlang.org/dmd-windows.html

## Linux ##
Requires wget, unzip, and dmd to all be on the PATH.
1. Clone repository (or download source archive)
2. Execute `build.sh`
3. Test the resuling `anaximander` executable.

## Apple OSX ##
I'm sorry, but OSX is not supported at this time.  Open source contributions are very welcome.  While I use a Mac myself, this program was developed because the original PHP scripts were not only very slow, but they were Linux-only and I had a need for a version that would run under Windows Server.  This kills two birds with one stone, but the third got away because I wasn't aiming for him!
