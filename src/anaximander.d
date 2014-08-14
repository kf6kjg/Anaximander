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

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Imports
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Standard imports.  Keep sorted.
import std.file;
import std.getopt;
import std.json;
import std.path;
import std.stdio;

// Local imports.  Keep sorted.
import alogger;
import atilegrabber;
import atilezoomer;
import aversioninfo;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Constants
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

private const string LGRP_APP = "app";


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Globals
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Globals are evil,
// Globals cause bugs,
// Globals are quick and easy until the correct better way shows up.


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Functions
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

int main(string[] args) {
	string config_file = "./anaximander.json"; /// Where in the world is the config file?
	JSONValue[string] config_document;
	
	// Tile paths
	string new_tile_path = "./newtiles"; /// The path for the tiles that yet need processing.
	string map_tile_path = "./maptiles"; /// The final output location for all finished tiles.
	string temp_tile_path = "./maptiles.temp"; /// Staging ground for tiles.
	
	bool do_call_get_tiles = false;
	
	// Process commandline parameters.
	getopt(args,
		std.getopt.config.caseSensitive,
		std.getopt.config.passThrough,
		std.getopt.config.bundling,
		"config", &config_file,
		"gettiles", &do_call_get_tiles,
		"logfile|l", &gLogFile,
		"logging|L", &gLogLevel,
		"quiet|q", function(){ gLogLevel = LOG_LEVEL.QUIET; },
		"verbose|v", function(){ gLogLevel = LOG_LEVEL.VERBOSE; },
	);
	
	// A friendly welcome.
	info(LGRP_APP, "Anaximander the Grid Cartographer at your service!");
	
	// Some things just need to happen after the greeting!
	getopt(args,
		std.getopt.config.caseSensitive,
		std.getopt.config.passThrough,
		std.getopt.config.bundling,
		"version|V", function(){ stdout.writefln(" Version %d", VERSION); },
	);
	
	// Verify the config path is sane.
	if (!config_file.isValidPath()) {
		err(LGRP_APP, "Invalid configuration file path: ", config_file);
		return -1;
	}
	
	// Normallize the config file path to the executable location if a relative path.
	if (!config_file.isAbsolute()) {
		config_file = buildNormalizedPath(thisExePath(), "..", config_file);
		chatter(LGRP_APP, "Normallized config file path to: ", config_file);
	}
	
	// Go attempt to read the config file.
	chatter(LGRP_APP, "Attempting to read the config file...");
	try {
		auto config_data = config_file.readText();
		try {
			JSONValue json_root = parseJSON(config_data);
			assert(json_root.type() == JSON_TYPE.OBJECT);
			config_document = json_root.object;
		}
		catch (Exception) {
			warn(LGRP_APP, "Invalid config file [", config_file, "]: Error parsing JSON format. Using defaults.");
		}
	}
	catch (Exception) {
		warn(LGRP_APP, "Config file not found [", config_file, "]. Using defaults.");
	}
	
	// Process config data.
	if (config_document.length) {
		debug_log(LGRP_APP, "Parsing values from config file.");
		if ("new_tile_path" in config_document) {
			new_tile_path = config_document["new_tile_path"].str;
			chatter(LGRP_APP, "Using new tile folder from config file: ", new_tile_path);
			scope(failure) err(LGRP_APP, "Invalid path in config file for key 'new_tile_path'.");
			assert(new_tile_path.isValidPath());
		}
		
		if ("map_tile_path" in config_document) {
			map_tile_path = config_document["map_tile_path"].str;
			chatter(LGRP_APP, "Using map tile folder from config file: ", map_tile_path);
			scope(failure) err(LGRP_APP, "Invalid path in config file for key 'map_tile_path'.");
			assert(map_tile_path.isValidPath());
		}
		
		if ("temp_tile_path" in config_document) {
			temp_tile_path = config_document["temp_tile_path"].str;
			chatter(LGRP_APP, "Using temp tile folder from config file: ", temp_tile_path);
			scope(failure) err(LGRP_APP, "Invalid path in config file for key 'temp_tile_path'.");
			assert(temp_tile_path.isValidPath());
		}
	}
	
	// Normallize the paths if they are relative paths.
	if (!new_tile_path.isAbsolute()) {
		new_tile_path = buildNormalizedPath(thisExePath(), "..", new_tile_path);
		chatter(LGRP_APP, "Normallized new tile folder path to: ", new_tile_path);
	}
	
	if (!map_tile_path.isAbsolute()) {
		map_tile_path = buildNormalizedPath(thisExePath(), "..", map_tile_path);
		chatter(LGRP_APP, "Normallized map tile folder path to: ", map_tile_path);
	}
	
	if (!temp_tile_path.isAbsolute()) {
		temp_tile_path = buildNormalizedPath(thisExePath(), "..", temp_tile_path);
		chatter(LGRP_APP, "Normallized  temp tile folder path to: ", temp_tile_path);
	}
	
	// If requested, gather tiles from regions.
	if (do_call_get_tiles) {
		chatter("Got request to get tiles from the regions.");
		ATileGrabber grabber = new ATileGrabber(config_document, new_tile_path);
		
		grabber.getRegionTiles();
	}
	
	
	// Create the ocean tile. Overwriting isn't much of an issue as this is trivial and fast - plus the temp folder should be empty.
	createOceanTile(config_document, temp_tile_path);
	
	return 0;
}
