# logjammer
p.codeexample {
    font-family: "Courier New";
}
New Relic
LogJammEr is comprised of three files:
<ul>
<li>logJammEr.pl  
<li>logJammEr.yml
<li>customEvents.cfg
<ul>
 <p>
<p>
<b>logJammEr.pl</b>
<p>
The main perl script, no modifications should be needed to this script.
<p>
<b>logJammEr.yml</b>
<p>
The site configuration file.  This file contains the configration options needed to integrate logfile based events into New Relic.  The following configuration options are available to be set in the configuration file:
 <table>
  <tr>
  <th>Option</th>
   <th>Description</th>
  </tr>
  <tr>
   <td>
 <b>debug</b>
   </td>
   <td>
 debug is used to generate verbose logging and stdout, the value is bolean.  1 is on 0 is off.
   </td>
  </tr>
  <tr>
   <td>
 <b>account</b>
   </td>
   <td>
 The New Relic account id to post events to
   </td>
  </tr>
  <tr>
   <td>
 <b>apiKey</b>
   </td>
   <td>
 The Insights API key to be used for posting events.
   </td>
  </tr>
  <tr>
 <td>
   <b>poll_interval</b>
  </td>
   <td>
 The interval in seconds that the logfiles listed should be polled.  All logfiles are polled at the same interval.
   </td>
  </tr>
  <tr>
   <td>
<b>logfile</b>
   </td>
   <td>
 Any logfiles that hould be watched are listed with a logfile parameter.  logfile=<i>path/file</i>
    </td>
    </tr>
    <tr>
    <td>
 <b>msgexps</b>
     </td>
     <td>
 The patterns file.  Pattern records have the following format:
 <ul>
  <li>eventtype=<i>New Relic required event type</i>
  <li>pattern=<i>regex pattern to match</i>
 <li>attributes=<i>parsed attributes from the record that are passed to New Relic as event attributes</i>
  </ul>
  </td>
  </table>
  <p>
   <b>customEvents.cfg</b>
 The patterns file.
