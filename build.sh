#!/bin/bash

# Assumes you have dmd installed and in your $PATH. If not, go get it: http://dlang.org/dmd-linux.html
# Also assumed that the following programs are installed so that automatic downloading of libraries can happen:
#  wget, unzip


# Get the version number
version="date +%Y%M%d%H"

# Process the version module to add the results into the source tree.
sed "s/%VERSION%/$version/" src/aversioninfo.d.in > src/aversioninfo.d

## Get libraries
mkdir lib
#if [ ! -e lib/FILE.zip ]; then ( cd lib; wget -O- http://SITE/FILE.zip | unzip - ); fi

## Compile the program
# Keep files in shell listing (alphanumerical) order
dmd -m64 -Dddoc -odobj -cov -unittest -inline -w \
	src/anaximander.d \
	src/atilegrabber.d \
	src/atilezoomer.d \
	src/aversioninfo.d \
