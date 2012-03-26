## M3

M3 => MMM => Monitis Monitor Manager

This is a utility that would help you to manage monitors in Monitis.

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
