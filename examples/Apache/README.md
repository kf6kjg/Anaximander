Apache can be used directly via setting the maptiles directory of Anaximander to your HTTP root directory, e.g. `/srv/www/map`, and setting the following options.

You may need to enable rewrite by executing the following:

```bash
sudo a2enmod rewrite
```

And then restart Apache.

# Using http.conf rules for Apache 2.4
This documents using a whole subdomain for the serving of the map tiles.  This is recommended, as you can then easily point the subdomain at any server, even a nice fast CDN, without having to change the URL in your grid's INI file.  However, you can easily change the following to work for a subdirectory of an existing domain - but I'll leave that as an exercise for the reader.

There is a couple of fundamental assumptions: the `tile_name_format` of `anaximander.json` is as default, and the `tile_file_type` is also the default.

Note: there are keys that need replacing in the below:
* Replace `SERVER_IP` with the IP address of your server.
* Replace `DOMAIN_NAME` with your main domain, e.g.: inworldz.com
* Replace `MAP_TILES_PATH` with the same path as Anaximander was configured to send the map tiles.  Remember: Anaximander needs permission to recreate this folder.  One technique could be to have this pointed at a symlink that is pointed at Anaximander's map_tiles_path.
* Replace `ocean.jpg` with the name that Anaximander was configured to name the ocean tile.  `ocean.jpg` is Anaximander's default.

```apache
<VirtualHost SERVER_IP:80>
	ServerAlias worldmap.DOMAIN_NAME *.worldmap.DOMAIN_NAME
	DocumentRoot "MAP_TILES_PATH"
	
	<Directory "MAP_TILES_PATH">
		Options FollowSymLinks
		Require all granted
		
		# Set up to handle file-not-found (aka a 404) with the ocean tile.
		ErrorDocument 404 /ocean.jpg
		
		# Now set up to handle requests of the form Z-X-Y, as requested from the viewer, or ?x=X&y=Y&z=Z - I'm not sure what wants this last style.
		RewriteEngine on
		
		# Convert the ?x=X&y=Y&z=Z form into Z-X-Y form
		RewriteCond %{QUERY_STRING} x=([0-9]+)&y=([0-9]+)&z=([0-9]+) [NC]
		RewriteRule ^$ map-%3-%1-%2-objects.jpg [QSD]
		
		# And catch all other ways of expressing the same, as query strings can be listed in any order: "xzy", "yxz", "yzx", "zxy", "zyx"
		RewriteCond %{QUERY_STRING} x=([0-9]+)&z=([0-9]+)&y=([0-9]+) [NC]
		RewriteRule ^$ map-%2-%1-%3-objects.jpg [QSD]
		RewriteCond %{QUERY_STRING} y=([0-9]+)&x=([0-9]+)&z=([0-9]+) [NC]
		RewriteRule ^$ map-%3-%2-%1-objects.jpg [QSD]
		RewriteCond %{QUERY_STRING} y=([0-9]+)&z=([0-9]+)&x=([0-9]+) [NC]
		RewriteRule ^$ map-%2-%3-%1-objects.jpg [QSD]
		RewriteCond %{QUERY_STRING} z=([0-9]+)&x=([0-9]+)&y=([0-9]+) [NC]
		RewriteRule ^$ map-%1-%2-%3-objects.jpg [QSD]
		RewriteCond %{QUERY_STRING} z=([0-9]+)&y=([0-9]+)&x=([0-9]+) [NC]
		RewriteRule ^$ map-%1-%3-%2-objects.jpg [QSD]
		
		# Exercise for the reader: handle extra parameters getting mixed into the query string!
		
		# Convert the Z-X-Y form into X-Y-Z.jpg - this form is what the viewer's world map goes looking for.
		RewriteRule ^map-([0-9]+)-([0-9]+)-([0-9]+)-objects.jpg$ /$2-$3-$1.jpg [PT,NC,QSD]
		
		# And finally, if there's a blank being asked for, serve up the ocean.  DirectoryIndex causes conflicts with the query string rewrites above.
		RewriteRule ^$ /ocean.jpg
	</Directory>
	
	ErrorLog ${APACHE_LOG_DIR}/error.log
	
	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn
	
	CustomLog ${APACHE_LOG_DIR}/access.log vhost_combined
</VirtualHost>
```
