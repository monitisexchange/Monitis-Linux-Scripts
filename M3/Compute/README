Compute plugins
---------------
 1. Math.pm - <math> - Simple calculations
 2. DiffPerSecond.pm - <diffpersec> - Calculate diffs

Math.pm (<math> directive)
--------------------------
Add, substract, multiply and divice with this simple plugin.
Examples:
 * <math>*2</math> => Multiply by 2
 * <math>/2</math> => Divide by 2
 * <math>+10</math> => Add 10
 * <math>-20</math> => Substract 20
Very useful to transform between bytes/Kbytes/Mbytes etc.

DiffPerSecond.pm (<diffpersec> directive)
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

The number you provide for <diffpersec> is the number of seconds between
samples, so for instance this:
 * <diffpersec>1</diffpersec> => Means diff per second (1 second)
 * <diffpersec>60</diffpersec> => Actually means diff per minute (60 seconds)

