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
import std.datetime;
import std.file;
import std.json;
import std.net.curl;
import std.path;
import std.parallelism;
import std.string;

// Library imports.  Keep sorted.
import dmagick.ColorRGB;
import dmagick.Geometry;
import dmagick.Image;
import mysql.connection;

// Local imports.  Keep sorted.
import alogger;
import aregiondata;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Constants
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

private const string LGRP_APP = "tilegrabber";

private const uint IMG_WIDTH = 256;
private const uint IMG_HEIGHT = 256;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Functions
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
* Gets the list of regions from the server.
*/
RegionData[] getRegionsFromDatabase(string connection_string)
	in {
		scope(failure) err(LGRP_APP, "Invalid connection string passed to getRegionsFromDatabase.");
		assert(connection_string.length > 0);
	}
	out {
		
	}
	body {
		// Open connection to the DB and get the records.
		auto conn = new Connection(connection_string);
		scope(exit) conn.close();
		
		RegionData[] region_data;
		
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
		
		return region_data;
	}

/**
* Go download the region tiles.
*/
void getRegionTiles(RegionData[] region_data, string new_tile_path, string filename_format, string file_ext)
	in {
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to getRegionTiles: '", new_tile_path, "'");
			assert(new_tile_path.length > 0);
			assert(new_tile_path.isValidPath());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file name format passed to getRegionTiles: '", filename_format, "'");
			assert(filename_format.length > 0);
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file extension passed to getRegionTiles: '", file_ext, "'");
			assert(file_ext.length > 0);
		}
	}
	out {
		
	}
	body {
		StopWatch sw;
		sw.start();
		scope(exit) {
			sw.stop();
			chatter(LGRP_APP, "Download took ", sw.peek().seconds, " seconds for ", region_data.length, " regions, resulting in ", cast(double)(sw.peek().seconds) / region_data.length, " seconds per region on average.");
		}
		
		foreach (rd; parallel(region_data, 1)) {
			getTileFromServer(rd.url, rd.x, rd.y, new_tile_path, filename_format, file_ext);
		}
	}

/**
* Grabs the tile image from the specified url and puts it in the predetermined file location.
*
* Note that this process takes about 1/2 second per call to a region, depending on the server and network speed.  Anything that can be done to reduce the number of calls is important!
*/
void getTileFromServer(string url, uint x_coord, uint y_coord, string new_tile_path, string filename_format, string file_ext)
	in {
		{
			scope(failure) err(LGRP_APP, "Invalid URL passed to getTileFromServer: '", url, "'");
			assert(url.length > 0);
		}
		{
			scope(failure) err(LGRP_APP, "URL must use http protocol: '", url, "'");
			assert(url[0..7].toLower == "http://");
		}
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to getTileFromServer: '", new_tile_path, "'");
			assert(new_tile_path.length > 0);
			assert(new_tile_path.isValidPath());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file name format passed to getTileFromServer: '", filename_format, "'");
			assert(filename_format.length > 0);
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file extension passed to getTileFromServer: '", file_ext, "'");
			assert(file_ext.length > 0);
		}
	}
	out {
		string filename = new_tile_path ~ "/" ~ filename_format.format(x_coord, y_coord, 1) ~ "." ~ file_ext;
		Image file;
		
		{
			scope(failure) err(LGRP_APP, "Failed to create tile from server. File: '", filename, "', URL: ", url);
			assert(filename.exists());
			assert(DirEntry(filename).size > 0);
			file = new Image(filename);
		}
		{
			scope(failure) err(LGRP_APP, "File on disk has wrong format: '" ~ file.magick().toLower() ~ "' and is supposed to be '" ~ file_ext.toLower() ~ "'. Corrupted download? File: '", filename, "', URL: ", url);
			string file_format = file.magick().toLower();
			assert((file_format == file_ext.toLower()) || (file_ext.toLower() == "jpg" && file_format == "jpeg"));
		}
	}
	body {
		file_ext = file_ext.toLower();
		
		string filename = new_tile_path ~ "/" ~ filename_format.format(x_coord, y_coord, 1) ~ "." ~ file_ext;
		
		bool image_was_written = false;
		
		try {
			chatter(LGRP_APP, "Grabbing tile from ", url);
			ubyte[] data = get!(AutoProtocol, ubyte)(url);
			
			chatter(LGRP_APP, "* Writing to ", filename);
			(new Image(data)).write(filename); // Converts the format automagickally if needed.
			image_was_written = true;
		}
		catch (CurlException e) {
			err(LGRP_APP, "Error downloading tile from region at (", x_coord, ", ", y_coord, ") with URL ", url, " - Error is: ", e);
		}
		
		if (!image_was_written) {
			// Could not get an image from the server. Slam an alternate image in its place.
			(new Image(Geometry(IMG_WIDTH, IMG_HEIGHT), new ColorRGB(255, 0, 0, 255))).write(filename); // TODO: Make this a configurable image not a hardcoded block of color!
		}
	}
