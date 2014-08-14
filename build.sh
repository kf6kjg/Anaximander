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
echo Gathering libraries, if any...
if [ ! -e lib/mysql-native ]; then (
	cd lib
	wget -O- https://github.com/rejectedsoftware/mysql-native/archive/v0.0.15.zip | unzip -d mysql-native -
	mkdir mysql
	cp mysql-native/source/mysql/* mysql/
); fi
#if [ ! -e lib/FILE ]; then ( cd lib; wget -O- http://SITE/FILE.zip | unzip - ); fi

## Compile the program
echo Generating docs and compiling...
rdmd -w -od. --build-only -m64 -Dddoc -cov -unittest -version=DMagick_No_Display -Ilib src\anaximander.d

chmod u+x anaximander
