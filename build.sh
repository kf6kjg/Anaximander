#!/bin/bash

# Assumes you have dmd installed and in your $PATH. If not, go get it: http://dlang.org/dmd-linux.html


# Get the version number
version="date +%Y%M%d%H"

# Process the version module to add the results into the source tree.
sed "s/%VERSION%/$version/" src/aversioninfo.d.in > src/aversioninfo.d

## Compile the program
# Keep files in shell listing (alphanumerical) order
dmd -m64 -Dddoc -odobj -cov -unittest -inline -w \
	src/anaximander.d \
	src/aversioninfo.d \
