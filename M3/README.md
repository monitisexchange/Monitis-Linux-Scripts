## M3

M3 => MMM => Monitis Monitor Manager

This is a utility that would help you to manage monitors in Monitis.

### M3 helper scripts

 * Run.pl - Executes all agents, then sends the monitoring data to Monitis.
 * DryRun.pl - Same as Run.pl, however does not send monitoring data to Monitis.
	Can be used to debug your parsing.
 * TimerRun.pl - Runs M3 in a loop using timers to schedule invocation of monitors
 * TimerDryRun.pl - Same as TimerRun.pl but does not send monitoring data to Monitis.
 * RunMassLoad.pl - Operates on the output line by line, very useful for mass
    loading of data obtained from log files.
 * DryRunMassLoad.pl - Same as RunMassLoad.pl but goes with a dry run.\
 * NagiosToM3Converter.pl will convert a nagios configuration to M3 - still work in progress
 * RRD/munin_xml_generator - Creates a M3 configuration from munin data

Any of these scripts can be composed by yourself, it's a simple perl line.
### M3 Plugin architecture

M3 has a plugin architecture. 3 types of plugins exist:
 1. Execution
 2. Parsing
 3. Compute
And they sit in the Execution, Parsing and Compute directories respectively.

### M3 phases

 * Execution plugins - Collecting output
 * Parsing plugins - picking the interesting data
 * Compute plugins - Post processing and transformation of data
 * Loading data to Monitis

<a href="http://blog.monitis.com/wp-content/uploads/2012/02/M3Flow.png"><img src="http://blog.monitis.com/wp-content/uploads/2012/02/M3Flow.png" title="M3 operation flow" /></a>

### Plugin documentation

 * <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3/Execution/README.md">Execution plugins</a>
 * <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3/Parsing/README.md">Parsing plugins</a>
 * <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3/Compute/README.md">Compute plugins</a>

### Very simple example

Inspecting the simplest example of M3 - etc&#95;file&#95;monitor.xml it'll
execute the command:

 # find /etc -maxdepth 1 -type f | wc -l

In order to collect the output and upload to Monitis you have to form a

regular expression, in this example it is:

&lt;regex&gt;(.*)&lt;/regex&gt;
Anything enclosed in parenthesis would be collected by the regular expression
plugin.

### Further reading
Learn more about Montis Monitor Manager Framework <a href="http://blog.monitis.com/index.php/tag/m3/">here</a>.
