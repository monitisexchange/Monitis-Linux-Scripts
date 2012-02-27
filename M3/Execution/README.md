Execution plugins
-----------------
 1. Executable.pm - <exectemplate> - Regular execution
 2. URL.pm - <url> - URL retrieval
 3. DBI.pm - <sql> - SQL execution via DBI
 4. LinuxSysStatistics.pm - <linuxsysstats> - Linux statistics
 5. Perl.pm - <perl> - Perl code execution

Executable.pm (<exectemplate> directive)
----------------------------------------
The simplest of all execution plugins, just executes the given command.
Can include redirects and pipes.
Anything can fit in, such as:
<exectemplate>ls -1 | wc -l</exectemplate>

URL.pm (<url> directive)
------------------------
Simply fetches a URL using CURL.
Any well formed URL is accepted:
<url>www.google.com</url>
<url>www.facebook.com</url>

DBI.pm (<sql> directive)
------------------------
Ported from the stand-alone <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/DBI">DBI module</a>.
This very powerful plugin lets you run SQL queries in front of any DBI
supported database.
Under the <sql> statement you are required to have a well format statement:
<sql>select count(*) from users;</sql>
Together with the <sql> directive, other connection data should be provided as well:
 * <db_driver> - Database driver (such as Pg, MySQL, etc.)
 * <db_name> - Database name
 * <db_host> - Database hostname to connect to, can be left blank to assume 'localhost'
 * <db_username> - Database username to connect with
 * <db_password> - Can be left blank if your password is blank

LinuxSysStatistics.pm (<linuxsysstats> directive)
-------------------------------------------------
Using the Sys::Statistics::Linux Perl Module, M3 can help you output invaluable
system counters.
Common examples are:
 * <linuxsysstats>cpustats->{cpu}{total}</linuxsysstats> - Total CPU usage
 * <linuxsysstats>memstats->{memtotal}</linuxsysstats> - Total memory
 * <linuxsysstats>memstats->{memused}</linuxsysstats> - Used memory
 * <linuxsysstats>diskusage->{/dev/sda1}{total}</linuxsysstats> - Total disk space on /dev/sda1
 * <linuxsysstats>diskusage->{/dev/sda1}{used}</linuxsysstats> - Used disk space on /dev/sda1
Please refer <a href="http://search.cpan.org/~bloonix/Sys-Statistics-Linux-0.63/lib/Sys/Statistics/Linux.pm">here</a> for the full manual.

Perl.pm (<perl> directive)
--------------------------
Easily embed perl code which would be evaluated during execution.
Any valid (multi line!!) perl code is accepted:
<perl>print "hello world!\n";</perl>
Please make sure to properly xmlencode your code as M3's configuration is XML.
