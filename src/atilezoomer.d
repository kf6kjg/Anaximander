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
import std.array;
import std.datetime;
import std.file;
import std.json;
import std.math;
import std.path;
import std.parallelism;
import std.string;

// Library imports.  Keep sorted.
import dmagick.Color;
import dmagick.ColorRGB;
import dmagick.Geometry;
import dmagick.Image;

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

/// Creates the ocean tile image that will be used for all missing tiles.
void createOceanTile(ubyte[3] ocean_color, string map_tile_path, string ocean_tile_file_name, string file_ext)
	in {
		{
			scope(failure) err(LGRP_APP, "Invalid ocean color passed to createOceanTile: ", ocean_color);
			assert(ocean_color[0] <= 255);
			assert(ocean_color[1] <= 255);
			assert(ocean_color[2] <= 255);
		}
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to createOceanTile: '", map_tile_path, "'");
			assert(map_tile_path.length > 0);
			assert(map_tile_path.isValidPath());
			assert(map_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid ocean tile file name passed to createOceanTile: '", ocean_tile_file_name, "'");
			assert(ocean_tile_file_name.length > 0);
			assert(ocean_tile_file_name.isValidFilename());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file extension passed to createOceanTile: '", file_ext, "'");
			assert(file_ext.length > 0);
		}
	}
	out {
		string filename = map_tile_path ~ "/" ~ ocean_tile_file_name ~ "." ~ file_ext.toLower();
		
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
			
			assert(abs(cast(byte)(ocean_color[0]) - pixels[0]) < 2); // Error of margin is because the values are slightly off, possibly compression, could be gamma...  Not sure.
			assert(abs(cast(byte)(ocean_color[1]) - pixels[1]) < 2);
			assert(abs(cast(byte)(ocean_color[2]) - pixels[2]) < 2);
		}
	}
	body {
		file_ext = file_ext.toLower();
		
		debug_log(LGRP_APP, "Creating background color.");
		Color background_color =  new ColorRGB(ocean_color[0], ocean_color[1], ocean_color[2], 255);
		
		debug_log(LGRP_APP, "Creating tile.");
		Image tile = new Image(Geometry(IMG_WIDTH, IMG_HEIGHT), background_color);
		
		string filename = map_tile_path ~ "/" ~ ocean_tile_file_name ~ "." ~ file_ext;
		
		chatter(LGRP_APP, "Saving ocean tile, colored ", ocean_color, " to ", filename);
		tile.write(filename);
	}

/// Places all needed tiles into the temp folder for processing.
void gatherRegionTiles(RegionData[] region_data, string temp_tile_path, string new_tile_path, string map_tile_path, string filename_format)
	in {
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to gatherRegionTiles: '", temp_tile_path, "'");
			assert(temp_tile_path.length > 0);
			assert(temp_tile_path.isValidPath());
			assert(temp_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to gatherRegionTiles: '", new_tile_path, "'");
			assert(new_tile_path.length > 0);
			assert(new_tile_path.isValidPath());
			assert(new_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to gatherRegionTiles: '", map_tile_path, "'");
			assert(map_tile_path.length > 0);
			assert(map_tile_path.isValidPath());
			assert(map_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file name format passed to gatherRegionTiles: '", filename_format, "'");
			assert(filename_format.length > 0);
		}
		{
			scope(failure) err(LGRP_APP, "File name format passed to gatherRegionTiles should have the file extension: '", filename_format, "'");
			assert(filename_format.indexOf(".") >= 0);
		}
	}
	out {
		// Nothing to check as it is not guaranteed that ANY files will exist: the most degenerate valid case is that the grid has no regions.
	}
	body {
		// Move the new tiles into the temp folder.
		foreach (d; parallel(new_tile_path.dirEntries(SpanMode.shallow), 1)) {
			// No need to worry about overwrite - there's not much there other than the ocean tile!
			d.name.rename(buildNormalizedPath(temp_tile_path, d.name.baseName()));
		}
		
		// Copy the valid region tiles into the temp folder.  Valid means that it is not already there, no overwriting, and that the region coord exists in the database.
		foreach (region; parallel(region_data, 1)) {
			string filename = filename_format.format(region.x, region.y, 1).baseName();
			
			string source = buildNormalizedPath(map_tile_path, filename);
			string dest = buildNormalizedPath(temp_tile_path, filename);
			
			// If already there don't overwrite as what's there is the newest.
			if (!dest.exists() && source.exists()) {
				source.copy(dest);
			}
		}
	}

/// Creates super-tile zoom levels, but only those that contain at least one region, and limited in depth by max_zoom_level.
void createZoomLevels(RegionData[] region_data, uint max_zoom_level, string new_tile_path, string temp_tile_path, string filename_format, ubyte[3] ocean_color)
	in {
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to createZoomLevels: '", new_tile_path, "'");
			assert(new_tile_path.length > 0);
			assert(new_tile_path.isValidPath());
			assert(new_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid path passed to createZoomLevels: '", temp_tile_path, "'");
			assert(temp_tile_path.length > 0);
			assert(temp_tile_path.isValidPath());
			assert(temp_tile_path.isDir());
		}
		{
			scope(failure) err(LGRP_APP, "Invalid file name format passed to createZoomLevels: '", filename_format, "'");
			assert(filename_format.length > 0);
		}
	}
	out {
		// Nothing to check as it is not guaranteed that ANY files will exist: the most degenerate valid case is that the grid has no regions.
	}
	body {
		Color background_color = new ColorRGB(ocean_color[0], ocean_color[1], ocean_color[2], 255);
		TileTree[string] full_list; // Stores every single TileTree element created by the below.  If this can be discarded in favor of some form of pointer magic in the actual elements so much the better.
		
		string[] top_layer; // The uppermost layer of the pyramid. Contains string indices into the full_list.
		
		StopWatch sw;
		sw.start();
		scope(exit) {
			sw.stop();
			chatter(LGRP_APP, "Super tile generation took ", sw.peek().msecs, " milliseconds for ", full_list.length - region_data.length, " super tiles, resulting in ", cast(double)(sw.peek().msecs) / (full_list.length - region_data.length), " milliseconds per super tile on average.");
		}
		
		// Efficiency note: the below may be rank with copies and other resource wastage.  At this time I do not yet have the knowledge base to discover them nor correct them.
		
		// Preload the algorithm with the region information.
		foreach (region; region_data) {
			string index = format("%d-%d-1", region.x, region.y);
			TileTree new_tree = { x: region.x, y: region.y, zoom: 1 };
			top_layer ~= index;
			full_list[index] = new_tree;
			full_list[index].children.length = 0; // 0 is the maximum number of children for a leaf.
		}
		
		debug_log(LGRP_APP, "Leaves: ", full_list);
		
		// Generate tree of tiles using a bottom-up breadth-first algorithm.
		for (uint zoom_level = 1; zoom_level < max_zoom_level; ++zoom_level) {
			debug_log(LGRP_APP, "Processing zoom level ", zoom_level);
			string[] current_layer;
			
			// Move the top layer into the current layer for the next pass.
			current_layer = top_layer[];
			top_layer.length = 0;
			
			debug_log(LGRP_APP, "* Current layer elements: ", current_layer);
			
			// Create the trees for the branches.
			foreach (node_index; current_layer) {
				debug_log(LGRP_APP, "* Processing index: ", node_index);
				TileTree branch = full_list[node_index];
				
				// Find super tile.
				uint super_x = (branch.x >>> zoom_level) << zoom_level; // = Math.floor(region.x / Math.pow(2, zoom_level)) * Math.pow(2, zoom_level)
				uint super_y = (branch.y >>> zoom_level) << zoom_level; // = Math.floor(region.y / Math.pow(2, zoom_level)) * Math.pow(2, zoom_level)
				string super_index = format("%d-%d-%d", super_x, super_y, zoom_level + 1);
				
				// Create the parent tree if needed.
				if (!(super_index in full_list)) {
					debug_log(LGRP_APP, "** Creating super with index: ", super_index);
					TileTree new_tree = { x: super_x, y: super_y, zoom: zoom_level + 1 };
					top_layer ~= super_index;
					full_list[super_index] = new_tree;
				}
				
				// Graft the current branch onto the tree.
				full_list[node_index].parent = super_index;
				full_list[super_index].children ~= node_index;
			}
		}
		
		//debug_log(LGRP_APP, "Tile tree: ", full_list);
		debug_log(LGRP_APP, "Top layer: ", top_layer);
		// Build the tile images using a post-order depth-first algorithm on the above trees.
		// Turns out this is not a trivial problem to solve.  Many thanks to Dave Remy: http://blogs.msdn.com/b/daveremy/archive/2010/03/16/non-recursive-post-order-depth-first-traversal.aspx
		foreach (tree_index; top_layer) {
			string[] to_visit;
			string[] visited_ancestors;
			to_visit ~= tree_index;
			
			while (to_visit.length > 0) {
				string branch_index = to_visit.back();
				TileTree branch = full_list[branch_index];
				
				if (branch.parent.length > 0) {
				// Process the node.
					TileTree parent = full_list[branch.parent];
					debug_log(LGRP_APP, "Processing branch(", branch_index, ") ", branch.x, "-", branch.y, "-", branch.zoom, "... with parent(", branch.parent, ") ", parent.x, "-", parent.y, "-", parent.zoom);
				}
				else {
					debug_log(LGRP_APP, "Processing branch(", branch_index, ") ", branch.x, "-", branch.y, "-", branch.zoom, "...");
				}
				
				if (branch.children.length > 0) {
					if (visited_ancestors.length == 0 || visited_ancestors.back() != branch_index) {
						visited_ancestors ~= branch_index;
						
						// Append the child list, but in reverse.
						foreach_reverse (child; branch.children) {
							to_visit ~= child;
						}
						
						continue;
					}
					
					visited_ancestors.popBack();
				}
				
				if (branch.zoom == 1) {
					// Zoom 1 is the definition of a leaf.
					string image_path = buildNormalizedPath(temp_tile_path, filename_format.format(branch.x, branch.y, branch.zoom));
					debug_log(LGRP_APP, "* Leaf. Attempting to load ", image_path);
					try {
						branch.tile_image = new Image(image_path);
						debug_log(LGRP_APP, "** Loaded.");
					}
					catch (Exception e) {
						debug_log(LGRP_APP, "** Failure to load.");
					} // If the file doesn't exist, then dinna worry 'bout it lad.
				}
				
				debug_log(LGRP_APP, "* Looking into processing the image.");
				// Ah, you are ready for reduction, export, and compiling into your parent then!
				
				// But if you are a leaf (region tile) then we'll let you slide...
				if (branch.zoom > 1) {
					// Scale down to IMG_WIDTH, IMG_HEIGHT
					debug_log(LGRP_APP, "** scaling.");
					branch.tile_image.sample(Geometry(IMG_WIDTH,IMG_HEIGHT));
					
					// Save to disk.
					string image_path = buildNormalizedPath(temp_tile_path, filename_format.format(branch.x, branch.y, branch.zoom));
					debug_log(LGRP_APP, "** exporting to ", image_path);
					branch.tile_image.write(image_path);
				}
				else {
					debug_log(LGRP_APP, "** No processing for region tiles.");
				}
				
				// Compile into parent tile.  Unless we are at the root of this tree!
				if (branch.parent.length > 0) {
					TileTree parent = full_list[branch.parent];
					debug_log(LGRP_APP, "** Compiling into parent(", branch.parent, ")");
					Image compilation = parent.tile_image;
					if (compilation is null) {
						compilation = new Image(Geometry(2 * IMG_WIDTH, 2 * IMG_HEIGHT), background_color);
					}
					
					// Add the tile to the correct spot.
					uint offset_x = ((branch.x - parent.x) * IMG_WIDTH) >>> (branch.zoom - 1);
					uint offset_y = IMG_HEIGHT - (((branch.y - parent.y) * IMG_HEIGHT) >>> (branch.zoom - 1)); // Y coordinates are reversed between images (+Y is down) and grid maps (+Y is up).
					
					debug_log(LGRP_APP, "*** at position ", offset_x, ",", offset_y);
					
					compilation.composite(
						branch.tile_image,
						CompositeOperator.ReplaceCompositeOp,
						offset_x,
						offset_y
					);
					
					full_list[branch.parent].tile_image = compilation;
				}
				
				// Remove from memory.
				full_list[branch_index].tile_image = null;
				
				// Done.
				to_visit.popBack();
			}
		}
	}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Structs/Classes
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

private struct TileTree {
	uint x;
	uint y;
	uint zoom;
	Image tile_image;
	string parent;
	string[] children;
}
