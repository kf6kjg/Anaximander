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

// Library imports.  Keep sorted.
import mysql.connection;

// Local imports.  Keep sorted.
import alogger;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Constants
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

private const string LGRP_APP = "tilegrabber";


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Classes
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// TODO: review if this couldn't be collapsed to a single function.
public class ATileGrabber {
	// Public methods, keep sorted.
	
	/**
	* Gets the list of regions from the server.
	*/
	void getRegionsFromDatabase(string connection_string) // *TODO: Should probably be private, and may want to be combined with getRegionTiles.
		in {
			assert(connection_string.length > 0);
		}
		out {
			
		}
		body {
			// Open connection to the DB and get the records.
			auto conn = new Connection(connection_string);
			scope(exit) conn.close();
			
			// *TODO: If possible, check to see if the dirtytile (or whatever it's called) column exists.  If it dows, use it in a where clause to limit the number of rows returned.  Possible use for a stored function, as the flag needs to be cleared as well...
			
			auto cmd = Command(conn, "SELECT uuid, serverIP, serverHttpPort, locX, locY FROM regions");
			ResultSet rs = cmd.execSQLResult();
			region_data.length = rs.length;
			debug_log(LGRP_APP, "SQL query returned ", region_data.length, " regions to get tiles from.");
			
			RegionData rd;
			for (uint index = 0; index < region_data.length; ++index) {
				rd.url = format("http://%s:%s/index.php?method=regionImage%s&forcerefresh=true", rs[index][1].toString(), rs[index][2].toString(), rs[index][0].toString().removechars("-"));
				rd.x = rs[index][3].get!(uint);
				rd.y = rs[index][4].get!(uint);
				
				region_data[index] = rd;
				debug_log(LGRP_APP, "Got region info: ", rd);
			}
		}
	
	/**
	* Go download the region tiles.
	*/
	void getRegionTiles()
		in {
			
		}
		out {
			
		}
		body {
			RegionData rd;
			for (uint index = 0; index < region_data.length; ++index) {
				rd = region_data[index];
				getTileFromServer(rd.url, rd.x, rd.y);
			}
		}
	
	/**
	* Grabs the tile image from the specified url and puts it in the predetermined file location.
	*
	* Note that this process takes about 1/2 second per call to a region, depending on the server and network speed.  Anything that can be done to reduce the number of calls is important!
	*/
	void getTileFromServer(string url, uint x_coord, uint y_coord)
		in {
			assert(url.length > 0);
			assert(url[0..7].toLower == "http://");
			assert(new_tile_path.length > 0);
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
			assert("database_connection" in config_document); // Required config entry.
		}
		out {
			assert(new_tile_path.isDir());
		}
		body {
			debug_log(LGRP_APP, "Tile grabber ctor'd");
			
			// Make sure the needed directory is there!
			this.new_tile_path = new_tile_path;
			if (!new_tile_path.exists()) {
				mkdirRecurse(new_tile_path);
			}
			
			// Get the tile name format from the config file if set.
			if ("tile_name_format" in config_document) { // Optional config entry.
				filename_format = config_document["tile_name_format"].str;
				chatter(LGRP_APP, "Using file format from config file: ", filename_format);
			}
			
			// Get the regions.
			getRegionsFromDatabase(config_document["database_connection"].str);
		}
	
	// Privates, keep sorted.
	private string filename_format = "%d-%d-%d.jpg";
	private string new_tile_path;
	private RegionData region_data[];
}

/**
* Stored region info as comes from the DB, with slight modification.
*/
private struct RegionData {
	string url; // = format("http://%s:%s/index.php?method=regionImage%s&forcerefresh=true", serverIP, serverHttpPort, serverUUID.removechars("-"))
	uint x;
	uint y;
}
