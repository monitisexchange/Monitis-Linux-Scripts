## Compute plugins

 1. Math.pm - &lt;math&gt; - Simple calculations
 2. DiffPerSecond.pm - &lt;diffpersec&gt; - Calculate diffs
 3. Min.pm - &lt;min&gt; - Calculate minimum value
 4. Max.pm - &lt;max&gt; - Calculate maximum value
 5. Average.pm - &lt;avg&gt; - Calculate average value

### Math.pm (&lt;math&gt; directive)

Add, substract, multiply and divice with this simple plugin.

Examples:

 * &lt;math&gt;*2&lt;/math&gt; => Multiply by 2
 * &lt;math&gt;/2&lt;/math&gt; => Divide by 2
 * &lt;math&gt;+10&lt;/math&gt; => Add 10
 * &lt;math&gt;-20&lt;/math&gt; => Substract 20

Very useful to transform between bytes/Kbytes/Mbytes etc.

### DiffPerSecond.pm (&lt;diffpersec&gt; directive)

DiffPerSecond saves data from previous execution and calculates diffs.

Say you have the following series of information (per second):
* * *
10

90

80
* * *

The series of results would be:
* * *
90-10 = 80

80-90 = -10
* * *

The number you provide for &lt;diffpersec&gt; is the number of seconds between samples, so for instance this:

 * &lt;diffpersec&gt;1&lt;/diffpersec&gt; => Means diff per second (1 second)
 * &lt;diffpersec&gt;60&lt;/diffpersec&gt; => Actually means diff per minute (60 seconds)

### Min.pm (&lt;min&gt; directive)

Calculate minimum value over few iterations

Example:

 * &lt;min&gt;10&lt;/min&gt; => Calculate minimum value of every 10 iterations

### Max.pm (&lt;max&gt; directive)

Calculate maximum value over few iterations

Example:

 * &lt;max&gt;10&lt;/max&gt; => Calculate maximum value of every 10 iterations

### Average.pm (&lt;avg&gt; directive)

Calculate average value over few iterations

Example:

 * &lt;avg&gt;10&lt;/avg&gt; => Calculate average value over every 10 iterations

