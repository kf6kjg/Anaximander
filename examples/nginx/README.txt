nxinx can be used directly via setting the maptiles directory of Anaximander to your HTTP root directory, e.g. `/srv/www/map`, and setting the following options.

# Using rules for nginx
This documents using a whole subdomain for the serving of the map tiles.  This is recommended, as you can then easily point the subdomain at any server, even a nice fast CDN, without having to change the URL in your grid's INI file.  However, you can easily change the following to work for a subdirectory of an existing domain - but I'll leave that as an exercise for the reader.

There is a couple of fundamental assumptions: the `tile_name_format` of `anaximander.json` is as default, and the `tile_file_type` is also the default.

Note: there are keys that need replacing in the below:
* Replace `SERVER_IP` with the IP address of your server, or remove to listen on all addresses.
* Replace `DOMAIN_NAME` with your main domain, e.g.: inworldz.com
* Replace `MAP_TILES_PATH` with the same path as Anaximander was configured to send the map tiles.  Remember: Anaximander needs permission to recreate this folder.  One technique could be to have this pointed at a symlink that is pointed at Anaximander's map_tiles_path.
* Replace `ocean.jpg` with the name that Anaximander was configured to name the ocean tile.  `ocean.jpg` is Anaximander's default.

```Nginx
server {
	listen SERVER_IP:80;
	server_name worldmap.DOMAIN_NAME *.worldmap.DOMAIN_NAME;
	
	error_page 404 /ocean.jpg;
	
	location / {
		root MAP_TILES_PATH;
		
		# Convert the ?x=X&y=Y&z=Z form into Z-X-Y form that comes from... I'm not sure.
		rewrite ^/$ /$arg_z-$arg_x-$arg_y?;
		
		# Convert the Z-X-Y form into X-Y-Z.jpg - this form is what the viewer's world map goes looking for.
		rewrite ^/([0-9]+)-([0-9]+)-([0-9]+)$ /$2-$3-$1.jpg;
		
		# And finally, if there's a blank being asked for, serve up the ocean.
		rewrite ^/$ /ocean.jpg;
	}
}
```
