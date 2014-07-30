@ECHO OFF

rem Assumes you have dmd installed and in your $PATH. If not, go get it: http://dlang.org/dmd-windows.html

dmd -m64 -Dddoc -odobj -cov -unittest -inline -w ^
	src/anaximander.d ^
