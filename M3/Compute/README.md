Compute plugins
---------------
 1. Math.pm - &lt;math&gt; - Simple calculations
 2. DiffPerSecond.pm - &lt;diffpersec&gt; - Calculate diffs

Math.pm (&lt;math&gt; directive)
--------------------------
Add, substract, multiply and divice with this simple plugin.
Examples:
 * &lt;math&gt;2&lt;/math&gt; => Multiply by 2
 * &lt;math&gt;2&lt;/math&gt; => Divide by 2
 * &lt;math&gt;10&lt;/math&gt; => Add 10
 * &lt;math&gt;20&lt;/math&gt; => Substract 20
Very useful to transform between bytes/Kbytes/Mbytes etc.

DiffPerSecond.pm (&lt;diffpersec&gt; directive)
-----------------------------------------
DiffPerSecond saves data from previous execution and calculates diffs.
Say you have the following series of information (per second):
---
10
90
80
---
The result would be:
90-10 = 80
80-90 = -10

The number you provide for &lt;diffpersec&gt; is the number of seconds between
samples, so for instance this:
 * &lt;diffpersec&gt;1&lt;/diffpersec&gt; => Means diff per second (1 second)
 * &lt;diffpersec&gt;60&lt;/diffpersec&gt; => Actually means diff per minute (60 seconds)

