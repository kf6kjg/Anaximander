#!/bin/bash

# Assumes you have dmd installed and in your $PATH. If not, go get it: http://dlang.org/dmd-linux.html
# Also assumed that the following programs are installed so that automatic downloading of libraries can happen:
#  wget, unzip
# And that you can compile C/C++ programs: sudo apt-get install build-essentials


proj_dir="${PWD}"
src_dir="${proj_dir}/src"
bin_dir="${proj_dir}/bin"
lib_dir="${proj_dir}/lib"
imports_dir="${proj_dir}/imports"


## Get the version into the source
# Get the version number
version="$(date +%Y%m%d%H)"

# Process the version module to add the results into the source tree.
sed "s/\@VERSION\@/$version/" "${src_dir}/aversioninfo.d.in" > "${src_dir}/aversioninfo.d"

## Create the needed folders
mkdir -p "${bin_dir}" 2> /dev/null
mkdir -p "${imports_dir}" 2> /dev/null
mkdir -p "${lib_dir}" 2> /dev/null


## Get libraries
echo "* Gathering libraries, if any..."

if [ "$(gcc -lcurl 2>&1 | grep '[-]lcurl' | wc -l)" -ge 1 ]; then # Not sure which is better: d/ling and compiling or asking for a system-wide install....
	echo "! Missing libcurl static library, cannot continue."
	echo "Please install a libcurl static library via one of the following, depending on your distro and preference:"
	echo "  $ sudo apt-get install libcurl4-openssl-dev"
	echo "  $ sudo apt-get install libcurl4-gnutls-dev # UNTESTED"
	echo "  $ sudo apt-get install libcurl4-nss-dev # UNTESTED"
	echo "  $ sudo yum install libcurl-devel openssl-devel # UNTESTED"
	echo " UNTESTED means simply that I have not verified that the command will work."
	exit 1
fi

if [ ! -e "${imports_dir}/mysql" ]; then
	echo "* Downloading mysql library..."
	mkdir -p "${lib_dir}/mysql-native"
	wget -O- "https://github.com/rejectedsoftware/mysql-native/archive/v0.0.15.tar.gz" | tar -xzC "${lib_dir}/mysql-native" --strip-components=1 || exit 1
	
	echo "* Gathering mysql library to imports folder..."
	mkdir -p "${imports_dir}/mysql" 2> /dev/null
	cp -R "${lib_dir}/mysql-native/source/mysql/"* "${imports_dir}/mysql/"
fi

# Requirement for proper build of ImageMagick
if [ "$(gcc -ljpeg 2>&1 | grep '[-]ljpeg' | wc -l)" -ge 1 ]; then # Not sure which is better: d/ling and compiling or asking for a system-wide install....
	echo "! Missing libjpeg static library, cannot continue."
	echo "Please install the libjpeg static library via one of the following, depending on your distro:"
	echo "  $ sudo apt-get install libjpeg-dev"
	echo "  $ sudo yum install libjpeg-devel # UNTESTED"
	echo " UNTESTED means simply that I have not verified that the command will work."
	exit 1
fi

# Requirement for proper build of ImageMagick
if [ "$(gcc -lgomp 2>&1 | grep '[-]lgomp' | wc -l)" -ge 1 ]; then # Not sure which is better: d/ling and compiling or asking for a system-wide install....
	echo "! Missing libgomp static library, cannot continue."
	echo "Please install the libgomp static library via one of the following, depending on your distro:"
	echo "  $ sudo apt-get install libgomp1v"
	#echo " UNTESTED means simply that I have not verified that the command will work."
	exit 1
fi

# Requirement for DMagick
if [ ! -e "${lib_dir}"/libMagickCore-*.a ]; then (
	echo "* Downloading ImageMagick library..."
	mkdir -p "${lib_dir}/imagemagick"
	wget -O- "http://www.imagemagick.org/download/ImageMagick.tar.xz" | tar -xJC "${lib_dir}/imagemagick" --strip-components=1 || exit 1
	
	# Build ImageMagick
	echo "* Building ImageMagick.  This may take a while; go get something to eat, have a drink, sing a song, or whatever..."
	(
		cd "${lib_dir}/imagemagick"
		./configure --without-x --without-magick-plus-plus --without-perl
		make
	) > /dev/null 2> /dev/null || exit 1
	
	# Go get what we want
	echo "* Gathering ImageMagick library files to library folder..."
	cp "${lib_dir}/imagemagick/magick/.libs/"* "${lib_dir}/"
	cp "${lib_dir}/imagemagick/wand/.libs/"* "${lib_dir}/"
); fi

if [ ! -e "${imports_dir}/dmagick" ]; then (
	echo "* Downloading DMagick library..."
	mkdir -p "${lib_dir}/dmagick"
	wget -O- "https://github.com/MikeWey/DMagick/archive/master.tar.gz" | tar -xzC "${lib_dir}/dmagick" --strip-components=1 || exit 1
	
	echo "* Gathering DMagick library to imports folder..."
	cp -R "${lib_dir}/dmagick/dmagick" "${imports_dir}/"
); fi


## Compile the program
echo "* Generating docs and compiling..."
rdmd -w -od${bin_dir} --build-only -m64 -Dddoc -cov -version=DMagick_No_Display -Iimports -L-l:lib/libMagickCore-6.Q16.a -L-l:lib/libMagickWand-6.Q16.a -L-ljpeg -L-lgomp -L-lphobos2 -L-lcurl "${src_dir}/anaximander.d" || exit 1
# Note: getting the linker flags in the correct order often takes adding the -v flag to see the resulting linker command.

chmod u+x "${bin_dir}/anaximander"


## Create execution script
echo "* Creating shell script for execution: ./anaximander.sh"
echo -e "#!/bin/bash
LD_LIBRARY_PATH=\"$(basename ${lib_dir})\" \"$(basename ${bin_dir})/anaximander\" \"\$@\"
" > "${proj_dir}/anaximander.sh"
chmod u+x "${proj_dir}/anaximander.sh"

echo "* To run anaximander:"
echo "  $ ./anaximander.sh"
