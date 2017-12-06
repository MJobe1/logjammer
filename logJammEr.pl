#!/usr/bin/perl
#+---------------------------------------------------------------------------+
#| PROGRAM NAME:      logJammEr                                              |
#| PROGRAM FUNCTION:  Logfile scanner and TCP event receiver.  Events that   |
#|                    are received are formatted based on rules and passed   |
#|                    into a New Relic RPM account.                          |
#| PROGRAM VERSION:   0.1  (alpha)                                           |
#|                           (c) Jobe :)                                     |
#+---------------------------------------------------------------------------+
# ---- WORK LOG -------------------------------------------------------------
# Nov-28/17   Michael Jobe -Initial Prototype
# Nov-30/17   Michael Jobe -Cleanup 
# ---------------------------------------------------------------------------
use LWP::UserAgent;

readConfig();
main();

# ----------------------------------------------------------------------------
# READ_CONFIG SUBROUTINE
# Read the configuration file, parse the results and load them into globally
# available variables where needed.
# ----------------------------------------------------------------------------
sub readConfig {
   our $hostname=`uname -n`;
   our $date=`date +%Y-%m-%d`;
   our $time=`date +%H:%M:%S`;
   chomp $hostname;
   chomp $date;
   chomp $time;
   if (!-f "logJammEr.yml") {
      $msg="LJ00097 LogJammEr configuration file <logJammEr.yml> does not exist in the execution directory.\n"; 
      ErrorOut();
   }
   else {
      open(CONFIG, "logJammEr.yml");
   }
   @config_data=<CONFIG>;
   foreach $config_option (@config_data)
      {
         if ($config_option =~ m/^\#/) {
            # Do nothing here...
         }
         else {
            ($key,$value)=split(/=/,$config_option,2);
            chomp $value;
            $config{$key}=$value;
            if ($key eq "logfile") {
               fileVerify($value); 
               push(@logfiles,$value);
            }
         }
      }
   our $debug=$config{debug};                        # Set debug switch
   our $apiKey=$config{apiKey};                      # New Relic APIKey 
   our $account=$config{account};                    # New Relic Account ID 
   our $debugfile=$config{debugfile};                # Set debug file 
   our $testMode=$config{testmode};                  # Test mode "0" meanse false
   our $pollInterval=$config{poll_interval};         # Number of seconds to wait
   our $sendErrMax=$config{max_errors};              # Error toleration level
   our $sendErrPause=$config{errorpause};            # Number of minutes to pause
   our $msgexps=$config{msgexps};                    # Pattern file
   our $firstRun=1;                                  # Set this as our first poll
   if (open(DEBUGFILE,">>$debugfile")) {             # DEBUGFILE Opened correctly
   }
   else { print "LJ000099 \tERROR opening debugfile: $debugfile\n"; }

   if ($debug) {
      debugOut("Printing LogJammEr Configuration Options:\n" . 
      "LJ00001 \tLogfile Debugging enabled...\n" .
      "LJ00001 \tNew Relic Account: $account\n" .
      "LJ00001 \tNew Relic Insights API Key: $apiKey\n" .
      "LJ00001 \tDebugging output will be written to $debugfile...\n" .
      "LJ00001 \tLogfile RegEx file: \t\t$msgexps\n" .
      "LJ00001 \tPolling interval: \t\t$pollInterval\n");
      foreach $logfile (@logfiles) {
        debugOut("LJ00001 \tLogfile to be watched: $logfile\n");
      }
   }
   getFileSize();
   getFormats($msgexps);
}
# ----------------------------------------------------------------------------
# MAIN Subroutine
# Main logic routine, wake up at designated intervals and check each file
# to be watched new records. 
# ----------------------------------------------------------------------------
sub main {
#
   while (1) {
      sleep $pollInterval;
      if ($firstRun) {
         foreach $log (@logfiles) {
            getFileSize($log);
            $logSize{$log}=$size;
         }
         $firstRun=0;
      }
      foreach $log (@logfiles) {
         open(LOGFILE,"<$log");
         getFileSize($log);
         if ($logSize{$log} < $size) {
            $ReadBytes=$size-$logSize{$log};
            seek(LOGFILE,$logSize{$log},0);
            getData();
            $logSize{$log}=$size;
         }
         elsif ($logSize{$log} > $size & $size > 0) { 
            # Need code here to handle "rolling" logfiles.
            debugOut("LJ00001 Looks as if the file $logfile rolled....\n");
            $readBytes=$size;
            seek(LOGFILE,0,0);
            getData();
         }
         close LOGFILE;
      } 
   }
}
# ----------------------------------------------------------------------------
# GETDATA Subroutine
# If new data is detected in the main routine, load new records from the last
# pointer.
# ----------------------------------------------------------------------------
sub getData {
   $AmountRead=read(LOGFILE,$NewEntries,$ReadBytes);
   if ($debug) {print DEBUGFILE "LJ00001 Bytes to be read from $Filename ($AmountRead)\n";}
      $_=$NewEntries;
      @NewLines=split(/(^.+$)/mg);
      foreach $line (@NewLines) {
         $cntr=0;
         $_=$line;
         foreach $exp (@Expression) {
            if (/$exp/) { 
               $outputString="{ \"eventType\":\"$Eventtype[$cntr]\",";
               @results=($line =~ /$exp/g);
               @lables=split(/,/,$Attributes[$cntr]);
               if ($debug) {
                  #print "LJ00001 \tInput line matched expression!\n";
               } 
               for ($comp=0; $comp<=$#results; $comp++) {
                  if ($results[$comp] =~ (/^-?\d+\.?\d*$/)) {
                     $newValue=$results[$comp];
                  }
                  else {
                     $newValue="\"" . $results[$comp] . "\"";
                  }
                  if ($comp==$#results) {
                     $outputString=$outputString . "\"" . $lables[$comp] . "\"" . ":" . $newValue . "}";
                  }
                  else {
                     $outputString=$outputString . "\"" . $lables[$comp] . "\"" . ":" . $newValue . ", ";   
                  }
               }
               sendData($outputString);
            }
            ++$cntr;
            $sendErrCount=0; 
            $outputString="";
        }
    }
}
# ----------------------------------------------------------------------------
# GETFILESIZE Subroutine
# routine to get file stats on watched files.
# ----------------------------------------------------------------------------
sub getFileSize($) {
   $filename=shift @_;
   ($dev,$inode,$mode,$numLink,$uid,$gid,$realDev,$size,$aTime,$mTime,$cTime,$blkSize)=stat($filename);
}
# ----------------------------------------------------------------------------
# FILEVERIFY Subroutines
# Verify the existence of configuration and watched files prior to running.
# ----------------------------------------------------------------------------
sub fileVerify($) {
   # First verify that the log to be wtched exists...
   $filename = shift @_;
   if (! -e $filename) {
      $msg="LJ00097 Logfile identified to be watched <$filename> does not exist\n"; 
      &ErrorOut;
   }
   if (! -r $filename) {
      $msg="LJ00097 Logfile identified to be watched <$filename> exists but is not readable\n"; 
      &ErrorOut;
   }
}
# ----------------------------------------------------------------------------
# SENDDATA Subroutine
# If new data is detected in a watched file, and a pattern match exists, send
# the data to New Relic.
# ----------------------------------------------------------------------------
sub sendData(@;$) {
   if ($debug) {print DEBUGFILE "LJ00001 Sending event to New Relic:\n";}
   print "FILENAME: $filename\n";
   $customJSON=shift @_;
   chomp(@_);
   my $nrEvent = LWP::UserAgent->new;
 
   my $server_endpoint = " https://insights-collector.newrelic.com/v1/accounts/" . $account . "/events";
   # set custom HTTP request header fields
   my $req = HTTP::Request->new(POST => $server_endpoint);
   $req->header('content-type' => 'application/json');
   $req->header('X-Insert-Key' => $apiKey);
 
   my $payload = $customJSON;
   $req->content("$payload");
 
   my $resp = $nrEvent->request($req);
   if ($resp->is_success) {
      my $message = $resp->decoded_content;
      debugOut("Sending the following event to New Relic: $message\n");
   }  
   else {
      debugOut("Unable to send event to New Relic, errors eperienced:\n");
      debugOut("HTTP POST error code: ", $resp->code, "\n");
      debugOut("HTTP POST error message: ", $resp->message, "\n");
   }
}
# ----------------------------------------------------------------------------
# GETFORMATS Subroutine
# Read and load the patterns for the events to send to New Relic.
# ----------------------------------------------------------------------------
sub getFormats($) {
   $log_cfg=shift @_;
   open(CFGFILE,"<$log_cfg");
   foreach $entry (<CFGFILE>) {
      $_=$entry;
      if (m/^\#.*$/) {
      }
      else {
         /^eventtype=(.+)\spattern=(.+)\sattributes=(.+)$/;
         $eventtype=$1;
         $exp=qr"$2";
         $attrib=$3;
         push(@Expression,$exp);
         push(@Eventtype,$eventtype);
         push(@Attributes,$attrib);
      }
   }
   if ($debug) {
      for ($index=0; $index <= $#Eventtype; $index++) {
         debugOut("LJ00001 Loading Format:\n");
         debugOut("LJ00001 \tEvent Type: $Eventtype[$index]\n");
         debugOut("LJ00001 \tExpression: $Expression[$index]\n");
         debugOut("LJ00001 \tAttributes: $Attributes[$index]\n");
      }
   }
   close(CFGFILE);
}
# ----------------------------------------------------------------------------
# DEBUGOUT Subroutine
# General debug routine.
# ----------------------------------------------------------------------------
sub debugOut($) {
   $debugMsg=shift @_;
   print DEBUGFILE "$debugMsg"; 
   print "$debugMsg"; 
}
# ----------------------------------------------------------------------------
# ERROROUT Subroutine
# General error routine.
# ----------------------------------------------------------------------------
sub ErrorOut {
   print "\nFatal error, exiting...\n";
   print "$msg";
exit;
}
