Map tile generator for [InWorldz][] servers using compiled D and the [ImageMagick][] library.

[InWorldz]: http://inworldz.com/
[ImageMagick]: http://www.imagemagick.org/

# Building source #

## Microsoft Windows ##
Requires Windows 7 or newer due to dependency on Microsoft PowerShell 2 or newer. Requires [dmd][] to be on the PATH.

1. Clone repository (or download source archive)
2. Execute `build.bat` (preferably with the Command Prompt)
3. If a Windows Explorer window opens and a message pops up, follow the instructions then repeat step 2.
4. Test the resulting `anaximander.exe` with the Windows Command Prompt.

[dmd]: http://dlang.org/dmd-windows.html

## Linux ##
Requires wget, unzip, and dmd to all be on the PATH.

1. Clone repository (or download source archive)
2. Install requirements: (If you skip this step the build script will tell you how to continue.)
  * libcurl
  * libjpeg
3. Set the build script executable:
    ```bash
    chmod u+x build.sh
    ```
4. Execute the build script:
    ```bash
    ./build.sh
    ```
5. Wait a while...
6. Test the resulting shell script to run the program:
    ```bash
    ./anaximander.sh
    ```

## Apple OSX ##
I'm sorry, but OSX is not supported at this time.  Open source contributions are very welcome.  While I use a Mac myself, this program was developed because the original PHP scripts were not only very slow, but they were Linux-only and I had a need for a version that would run under Windows Server.  This kills two birds with one stone, but the third got away because I wasn't aiming for him!
