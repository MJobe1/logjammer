# logjammer
New Relic
LogJammEr is comprised of three files:
-logJammEr.pl  
-logJammEr.yml
-customEvents.cfg

logJammEr.pl
The main perl script, no modifications should be needed to this script.

logJammEr.yml
the site configuration file.  This file contains the configration options needed to integrate logfile based events into New Relic.
The following configuration options are available:
-debug
 debug is used to generate verbose logging and stdout, the value is bolean.  1 is on 0 is off.
-account
 The New Relic account id to post events to
-apiKey
 The Insights API key to be used for posting events.
poll_interval
 The interval in seconds that the logfiles listed should be polled.  All logfiles are polled at the same interval.
-logfile
 Any logfiles that hould be watched are listed with a logfile parameter.  logfile=<path>/<file>
-msgexps
 The patterns file.  Pattern records have the following format:
 eventtype=<New Relic required event type>
 pattern=<regex pattern to match>
 attributes=<parsed attributes from the record that are passed to New Relic as event attributes>
 
 customEvents.cfg
 The patterns file.
