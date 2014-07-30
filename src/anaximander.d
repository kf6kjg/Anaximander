/**
* Core logic and main.
*
* Anaximander Grid Carographer for InWorldz or related grids.
* 
* Copyright: Copyright (c) 2014 Richard Curtice
* License: The MIT License (MIT)
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import std.stdio;
import std.getopt;

const uint VER_MAJOR = 0;
const uint VER_MINOR = 0;
const uint VER_BUILD = 1;

int main(string[] args) {
	writeln("Anaximander the Grid Cartographer at your service!");
	
	getopt(args,
		"version|V", function void() {writefln(" Version %d.%d.%d", VER_MAJOR, VER_MINOR, VER_BUILD);}
	);
	
	return 0;
}
