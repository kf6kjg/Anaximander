/**
* A simple logging facility.
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
module alogger;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Imports
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Standard imports.  Keep sorted.
import std.datetime;
import std.stdio;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Types
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

enum LOG_LEVEL {
	DEBUG, /// Debugging messages only.
	VERBOSE, /// Helpful, if a mite chatty, messages.
	NORMAL, /// Only helpful messages.
	QUIET /// Try NOT to send messages across this level.
}

enum LOG_TYPE {
	NORMAL, /// Helpful messages.
	WARNING, /// For the times when there's somethign wrong but we can keep on trucking.
	ERROR /// Fails only.
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Globals
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

LOG_LEVEL gLogLevel = LOG_LEVEL.NORMAL;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
// Functions
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/// Core logging function.  Please use one of the other logging functions.
private void log(Args...)(LOG_LEVEL level, LOG_TYPE type, string group, Args values)
	in {
		{
			scope(failure) stderr.writeln("Attempted to log against a non-valid group title: '", group, "'");
			assert(group.length > 0);
		}
	}
	body {
		if (level >= gLogLevel) {
			auto now = (cast(DateTime)(Clock.currTime())).toISOString(); // Local time.
			
			switch (type) {
				case LOG_TYPE.WARNING:
					stderr.writeln(now, "[", group, "]W: ", values);
				break;
				case LOG_TYPE.ERROR:
					stderr.writeln(now, "[", group, "]E: ", values);
				break;
				default:
					writeln(now, "[", group, "]N: ", values);
			}
		}
	}

/// Alias for log(LOG_LEVEL.NORMAL, LOG_TYPE.NORMAL, group, values);
void info(Args...)(string group, Args values) {
	log(LOG_LEVEL.NORMAL, LOG_TYPE.NORMAL, group, values);
}

/// Alias for log(LOG_LEVEL.VERBOSE, LOG_TYPE.NORMAL, group, values);
void chatter(Args...)(string group, Args values) {
	log(LOG_LEVEL.VERBOSE, LOG_TYPE.NORMAL, group, values);
}

/// Alias for log(LOG_LEVEL.DEBUG, LOG_TYPE.NORMAL, group, values);
void debug_log(Args...)(string group, Args values){
	log(LOG_LEVEL.DEBUG, LOG_TYPE.NORMAL, group, values);
}

/// Alias for log(LOG_LEVEL.QUIET, LOG_TYPE.WARNING, group, values);
void warn(Args...)(string group, Args values) {
	log(LOG_LEVEL.QUIET, LOG_TYPE.WARNING, group, values);
}

/// Alias for log(LOG_LEVEL.QUIET, LOG_TYPE.ERROR, group, values);
void err(Args...)(string group, Args values) {
	log(LOG_LEVEL.QUIET, LOG_TYPE.ERROR, group, values);
}
