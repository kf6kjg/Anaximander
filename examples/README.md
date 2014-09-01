While the details of setting up the InWorldz grid, OpenSimulator grid, or even a given web server is out of scope of this project, there is a need for some documentation on how to integrate Anaximander with them.

# Setting up the map tile server
In the various folders under this location are example configurations for setting up a website, or page depending on the example, that serves the map tiles to the viewer.  Some are faster than others, others not so much.

Of the various options I would use one that utilizes just the web server and url rewriting without any server-side code.  These will run faster and use much less memory.

I also suggest to set up a custom subdomain for the map server, as this will allow you to change configuration easily in the future should your bandwidth and speed needs change.  Something like `worldmap.example.com` should work great.

The folder the map server is getting the map image tiles from is rebuilt by Anaximander every time Anaximander updates the maps.  This is to keep changeover time to a minimum: Anaximander creates a temporary folder, rebuilds or copies the needed map image tiles into it, then moves the temporary folder overtop of the old map folder.  Moving a directory in this way takes a very small amount of time, nanoseconds on most systems, vs copying and creating all the tiles which can take up to several minutes.

This overwriting of the folder means that the document root of your web site needs to be in a place Anaximander can have complete control over.  Be sure to take this into account when designating where on the filesystem you are placing it and the permissions involved.

# Configuring the grid for a world map
Once you've set up web site for hosting the map tiles, you can add the url to the grid configuration file, which will be either `OpenSim.ini` or `Robust.ini` depending on which grid server you are running and its version.

If you are working with `OpenSim.ini` then you'll be looking for the `MapImageServerURI` key and setting it to your map domain like so:

```INI
MapImageServerURI = "http://worldmap.example.com"
```

If you are working with `Robust.ini` then you'll be looking for `MapTileURL` and setting it to your map domain, like so:

```INI
MapTileURL = "http://worldmap.example.com"
```

Of course you'll need to replace `example.com` with your domain.

# Scheduling Anaximander
Scheduling Anaximander to run regularly is particularly OS-specific, and has a lot of options depending on your set up.

## UNIX clones (aka Linux)
In UNIX clones such as Linux, you'll be wanting to set up a cronjob under the user, not root, that has the permissions to create files in the directory that is the destination for the maptiles directory - which is also doubling as the document root of the above server, but you already knew that!  The cronjob will simply execute the `anaximander.sh` script, possibly with the [`--gettiles` flag][flags]:

```
# Set for once every week, Wednesday at midnight:
0	0	*	*	3	/path/to/anaximander.sh --gettiles -v -V >> /another/path/anaximander.log
```

Note that stderr is not redirected to the file: this is so that the user will get an email if a crash-level error occurs.

[flags]: https://github.com/kf6kjg/Anaximander/wiki/Command%20line%20flags

## Microsoft Windows
In Windows you'll need to set up a job using Windows Scheduler.
