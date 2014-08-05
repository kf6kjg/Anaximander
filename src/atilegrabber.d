/**
* Gathers all needed tiles from the relevant region servers and stores them for later processing.
* 
* This is an extra optional step that will hopefully be deprecated by a more active approach from the region servers.
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
module atilegrabber;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Imports
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Standard imports.  Keep sorted.
import std.file;
import std.json;
import std.net.curl;
import std.string;

// Local imports.  Keep sorted.
import alogger;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Constants
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

const string LGRP_APP = "tilegrabber";


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Classes
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public class ATileGrabber {
	// Public methods, keep sorted.
	
	/**
	* Grabs the tile image from the specified url and puts it in the predetermined file location.
	*/
	void getTileFromServer(string url, uint x_coord, uint y_coord)
		in {
			assert(url.length > 0);
			assert(url[0..7].toLower == "http://");
		}
		out {
			string filename = new_tile_path ~ "/" ~ filename_format.format(x_coord, y_coord, 1);
			assert(filename.exists());
			assert(DirEntry(filename).size > 0);
		}
		body {
			string filename = new_tile_path ~ "/" ~ filename_format.format(x_coord, y_coord, 1);
			chatter(LGRP_APP, "Grabbing tile from ", url, " and writing to ", filename);
			write(filename, get(url));
		}
	
	// Public properties, keep sorted.
	
	// Public ctors, keep sorted.
	
	this(JSONValue[string] config_document, string new_tile_path)
		in {
			assert(new_tile_path.length > 0);
		}
		body {
			debug_log(LGRP_APP, "Tile grabber ctor'd");
			
			if ("tile_name_format" in config_document) {
				filename_format = config_document["tile_name_format"].str;
				chatter(LGRP_APP, "Using file format from config file: ", filename_format);
			}
			this.new_tile_path = new_tile_path;
			
			// Make sure the needed directory is there!
			if (!new_tile_path.exists()) {
				mkdirRecurse(new_tile_path);
			}
			assert(new_tile_path.isDir());
		}
	
	// Privates, keep sorted.
	private string filename_format = "%d-%d-%d.jpg";
	private string new_tile_path;
}
