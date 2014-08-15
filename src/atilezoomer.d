/**
* Loads changed tiles and creates composites for the higher zoom levels.
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
module atilezoomer;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Imports
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Standard imports.  Keep sorted.

import std.file;
import std.json;
import std.math;
import std.path;
import std.string;

// Library imports.  Keep sorted.
import dmagick.Color;
import dmagick.ColorRGB;
import dmagick.Geometry;
import dmagick.Image;

// Local imports.  Keep sorted.
import alogger;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Constants
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

private const string LGRP_APP = "tilegrabber";

private const uint IMG_WIDTH = 256;
private const uint IMG_HEIGHT = 256;
private const ubyte[] OCEAN_COLOR = [ 1, 11, 252 ];

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Functions
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/// Creates the ocean tile image that will be used for all missing tiles.
void createOceanTile(JSONValue[string] config_document, string map_tile_path, string file_ext)
	in {
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to createOceanTile: '", map_tile_path, "'");
			assert(map_tile_path.length > 0);
			assert(map_tile_path.isValidPath());
			assert(map_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file extention passed to createOceanTile: '", file_ext, "'");
			assert(file_ext.length > 0);
		}
		{
			scope(failure) err(LGRP_APP, "Key ocean_tile_name missing from config file!");
			assert("ocean_tile_name" in config_document); // Required config entry.
		}
		{
			scope(failure) err(LGRP_APP, "Value for config file key 'ocean_tile_name' is not a string!");
			assert(config_document["ocean_tile_name"].type() == JSON_TYPE.STRING);
		}
		{
			scope(failure) err(LGRP_APP, "Value for config file key 'ocean_tile_name' is not a valid file name!");
			assert(config_document["ocean_tile_name"].str.length > 0);
			assert(config_document["ocean_tile_name"].str.isValidFilename());
		}
	}
	out {
		string filename = map_tile_path ~ "/" ~ config_document["ocean_tile_name"].str ~ "." ~ file_ext.toLower();
		
		{
			scope(failure) err(LGRP_APP, "Function failed to create ocean tile at ", filename);
			assert(filename.exists());
		}
		{
			scope(failure) err(LGRP_APP, "Function failed to put data in ocean tile at ", filename);
			assert(DirEntry(filename).size > 0);
		}
		{
			scope(failure) err(LGRP_APP, "Function failed to fill in ocean tile with the correct color at ", filename);
			Image tile = new Image(filename);
			// Get the pixel.
			byte[3] pixels;
			tile.exportPixels(Geometry(1,1, 10,10), pixels, "RGB");
			// test it
			ubyte[3] correct_color;
			
			if ("ocean_color" in config_document) { // Optional config entry.
				correct_color[0] = cast(ubyte)(config_document["ocean_color"].array[0].integer());
				correct_color[1] = cast(ubyte)(config_document["ocean_color"].array[1].integer());
				correct_color[2] = cast(ubyte)(config_document["ocean_color"].array[2].integer());
			}
			else {
				correct_color[0] = OCEAN_COLOR[0];
				correct_color[1] = OCEAN_COLOR[1];
				correct_color[2] = OCEAN_COLOR[2];
			}
			
			assert(abs(cast(byte)(correct_color[0]) - pixels[0]) < 2); // Error of margin is because the values are slightly off, possibly compression, could be gamma...  Not sure.
			assert(abs(cast(byte)(correct_color[1]) - pixels[1]) < 2);
			assert(abs(cast(byte)(correct_color[2]) - pixels[2]) < 2);
		}
	}
	body {
		ubyte[3] bg_color;
		
		file_ext = file_ext.toLower();
		
		if ("ocean_color" in config_document) { // Optional config entry.
			scope(failure) err(LGRP_APP, "Value for config key 'ocean_color' MUST be an array of three (3) positive integers!");
			assert(config_document["ocean_color"].type == JSON_TYPE.ARRAY);
			assert(config_document["ocean_color"].array.length == 3);
			assert(config_document["ocean_color"].array[0].type == JSON_TYPE.INTEGER);
			assert(config_document["ocean_color"].array[0].integer() >= 0);
			assert(config_document["ocean_color"].array[1].type == JSON_TYPE.INTEGER);
			assert(config_document["ocean_color"].array[1].integer() >= 0);
			assert(config_document["ocean_color"].array[2].type == JSON_TYPE.INTEGER);
			assert(config_document["ocean_color"].array[2].integer() >= 0);
			
			bg_color[0] = cast(ubyte)(config_document["ocean_color"].array[0].integer());
			bg_color[1] = cast(ubyte)(config_document["ocean_color"].array[1].integer());
			bg_color[2] = cast(ubyte)(config_document["ocean_color"].array[2].integer());
			chatter(LGRP_APP, "Using ocean color from config file: ", bg_color);
		}
		else {
			bg_color[0] = OCEAN_COLOR[0];
			bg_color[1] = OCEAN_COLOR[1];
			bg_color[2] = OCEAN_COLOR[2];
		}
		
		debug_log(LGRP_APP, "Creating background color.");
		Color background_color =  new ColorRGB(bg_color[0], bg_color[1], bg_color[2], 255);
		
		debug_log(LGRP_APP, "Creating tile.");
		Image tile = new Image(Geometry(IMG_WIDTH, IMG_HEIGHT), background_color);
		
		string filename = map_tile_path ~ "/" ~ config_document["ocean_tile_name"].str ~ "." ~ file_ext;
		
		chatter(LGRP_APP, "Saving ocean tile, colored ", bg_color, " to ", filename);
		tile.write(filename);
	}
