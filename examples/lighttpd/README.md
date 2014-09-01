lighttpd can be used directly via setting the maptiles directory of Anaximander to your HTTP root directory, e.g. `/srv/www/map`, and setting the following options.

# Using lighttpd
This documents using a whole subdomain for the serving of the map tiles.  This is recommended, as you can then easily point the subdomain at any server, even a nice fast CDN, without having to change the URL in your grid's INI file.  However, you can easily change the following to work for a subdirectory of an existing domain - but I'll leave that as an exercise for the reader.

There is a couple of fundamental assumptions: the `tile_name_format` of `anaximander.json` is as default, and the `tile_file_type` is also the default.

Note: there are keys that need replacing in the below:
* Replace `SERVER_IP` with the IP address of your server, or remove to listen on all addresses.
* Replace `DOMAIN_NAME` with your main domain, making sure to escape any regex, e.g.: inworldz\.com
* Replace `MAP_TILES_PATH` with the same path as Anaximander was configured to send the map tiles.  Remember: Anaximander needs permission to recreate this folder.  One technique could be to have this pointed at a symlink that is pointed at Anaximander's map_tiles_path.
* Replace `ocean.jpg` with the name that Anaximander was configured to name the ocean tile.  `ocean.jpg` is Anaximander's default.

```INI
# Remember to wrap the folowing line in global {...} if you are placing this in an included file.
server.modules += ("mod_rewrite")

$HTTP["host"] =~ "(^|\.)worldmap\.DOMAIN_NAME$" {
	server.bind = "SERVER_IP" # Remove this line if you want to bind to all addresses.
	server.port = 80
	
	server.document-root = "MAP_TILES_PATH"
	
	server.error-handler-404 = "/ocean.jpg"
	
	url.rewrite-repeat = (
		 # Convert the ?x=X&y=Y&z=Z form into Z-X-Y form that comes from... I'm not sure.
		"x=([0-9]+)&y=([0-9]+)&z=([0-9]+)" => "/map-$3-$1-$2-objects.jpg",
		 # And catch all other ways of expressing the same, as query strings can be listed in any order: "xzy", "yxz", "yzx", "zxy", "zyx"
		"x=([0-9]+)&z=([0-9]+)&y=([0-9]+)" => "/map-$2-$1-$3-objects.jpg",
		"y=([0-9]+)&x=([0-9]+)&z=([0-9]+)" => "/map-$3-$2-$1-objects.jpg",
		"y=([0-9]+)&z=([0-9]+)&x=([0-9]+)" => "/map-$2-$3-$1-objects.jpg",
		"z=([0-9]+)&x=([0-9]+)&y=([0-9]+)" => "/map-$1-$2-$3-objects.jpg",
		"z=([0-9]+)&y=([0-9]+)&x=([0-9]+)" => "/map-$1-$3-$2-objects.jpg",
		
		# Exercise for the reader: handle extra parameters getting mixed into the query string!
		
		 # Convert the Z-X-Y form into X-Y-Z.jpg - this form is what the viewer's world map goes looking for.
		"^/map-([0-9]+)-([0-9]+)-([0-9]+)-objects.jpg$" => "/$2-$3-$1.jpg",
		
		# And finally, if there's a blank being asked for, serve up the ocean.
		"^/$" => "/ocean.jpg",
	)
}
```
