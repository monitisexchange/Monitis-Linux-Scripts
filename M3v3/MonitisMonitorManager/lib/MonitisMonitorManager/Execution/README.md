## Execution plugins

 1. Executable.pm - &lt;exectemplate&gt; - Regular execution
 2. URL.pm - &lt;url&gt; - URL retrieval
 3. DBI.pm - &lt;sql&gt; - SQL execution via DBI
 4. LinuxSysStatistics.pm - &lt;linuxsysstats&gt; - Linux statistics
 5. Perl.pm - &lt;perl&gt; - Perl code execution
 6. SNMP.pm - &lt;oid&gt; - SNMP OID query
 7. RemoteCommand.pm - &lt;remote_command&gt; - Remote command such as SSH or telnet

### Executable.pm (&lt;exectemplate&gt; directive)

The simplest of all execution plugins, just executes the given command.

Can include redirects and pipes.

Anything can fit in, such as:

 * &lt;exectemplate&gt;ls -1 | wc -l&lt;/exectemplate&gt;

### URL.pm (&lt;url&gt; directive)

Simply fetches a URL using CURL.

Any well formed URL is accepted:

 * &lt;url&gt;
     &lt;url&gt;www.google.com &lt;/url&gt;
   &lt;/url&gt;
 * &lt;url&gt;
     &lt;url&gt;www.facebook.com &lt;/url&gt;
     &lt;statistics&gt;1&lt;/statistics&gt; - Add statistics to query
   &lt;/url&gt;

### DBI.pm (&lt;sql&gt; directive)

Ported from the stand-alone <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/DBI">DBI module</a>

This very powerful plugin lets you run SQL queries in front of any DBI supported database.

Under the &lt;query&gt; statement you are required to have a well format statement:

 * &lt;query&gt;select count(*) from users;&lt;/query&gt;

Together with the &lt;sql&gt; directive, other connection data should be provided as well:<br>

 * &lt;driver&gt; - Database driver (such as Pg, MySQL, etc.)
 * &lt;name&gt; - Database name
 * &lt;hostname&gt; - Database hostname to connect to, can be left blank to assume 'localhost'
 * &lt;username&gt; - Database username to connect with
 * &lt;password&gt; - Can be left blank if your password is blank

Example can be found in <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3v3/monitis-m3/usr/local/share/monitis-m3/sample_config/dbi_sample.xml">here</a>

### LinuxSysStatistics.pm (&lt;linuxsysstats&gt; directive)

Using the Sys::Statistics::Linux Perl Module, M3 can help you output invaluable system counters.

Common examples are:

 * &lt;linuxsysstats&gt;cpustats-&gt;{cpu}{total}&lt;/linuxsysstats&gt; - Total CPU usage
 * &lt;linuxsysstats&gt;memstats-&gt;{memtotal}&lt;/linuxsysstats&gt; - Total memory
 * &lt;linuxsysstats&gt;memstats-&gt;{memused}&lt;/linuxsysstats&gt; - Used memory
 * &lt;linuxsysstats&gt;diskusage-&gt;{/dev/sda1}{total}&lt;/linuxsysstats&gt; - Total disk space on /dev/sda1
 * &lt;linuxsysstats&gt;diskusage-&gt;{/dev/sda1}{used}&lt;/linuxsysstats&gt; - Used disk space on /dev/sda1

Please refer to <a href="http://search.cpan.org/~bloonix/Sys-Statistics-Linux-0.63/lib/Sys/Statistics/Linux.pm">here</a> for the full manual.

### Perl.pm (&lt;perl&gt; directive)

Easily embed perl code which would be evaluated during execution.

Any valid (multi line!!) perl code is accepted:

 * &lt;perl&gt;print "hello world!\n";&lt;/perl&gt;

Please make sure to properly xmlencode your code as M3's configuration is XML.

### SNMP.pm (&lt;oid&gt; directive)

Query a SNMP oid.

Simply include your oid in the configuration:

 * &lt;oid&gt;.1.3.6.1.2.1.1.3.0&lt;/oid&gt;

Two other parameters may be specified:

 * &lt;hostname&gt; - SNMP hostname to query ("localhost" will be used if unspecified)
 * &lt;community&gt; - SNMP community to use for query ("public" will be used if unspecified)

Example can be found in <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3v3/monitis-m3/usr/local/share/monitis-m3/sample_config/snmp_test.xml">here</a>

### RemoteCommand.pm (&lt;remote_command&gt; directive)

Query a remote server using SSH or Telnet.

Include your command in the configuration:

 * &lt;remote_command&gt;ls -l /etc | wc -l&lt;/remote_command&gt;

Few other parameters must be specified:

 * &lt;protocol&gt; - Protocol to use, currently 'ssh' and 'telnet' are supported
 * &lt;hostname&gt; - Hostname to connect to
 * &lt;username&gt; - Username to use
 * &lt;password&gt; - Password to use

Optional parameters:

 * &lt;port&gt; - Port to use, if unspecified the default port would be used

