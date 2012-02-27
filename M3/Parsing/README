Parsing plugins
---------------
 1. LineNumber.pm - <line> - Extract whole line
 2. Regex.pm - <regex> - Regular expression
 3. XPath.pm - <xpath> - XML XPath
 4. JSON.pm - <json> - JSON path

LineNumber.pm (<line> directive)
--------------------------------
Perhaps the simplest parsing plugin M3 has to offer.
This plugin will extract a whole line from the output.
Having for instance the output of:
---
Hello
World
!
---
Would result in the following parsing:
<line>1</line> => Hello
<line>2</line> => World
<line>3</line> => !

Regex.pm (<regex> directive)
----------------------------
The first and perhaps most powerful parsing plugins M3 has to offer.
Regular expressions are extremely simple yet very powerful and flexible.
Numerous examples exist in the different sample configuration files.
The regex plugin most commonly used feature is to extract the whole output:
<regex>(.*)</regex>
For instance, extracting the second word in a sentence would be:
---
The quick brown fox jumps over the lazy dog
---
<regex>\w+\s+(\w+)</regex> => quick

If you are unfamiliar with regular expressions and would still like to use
them, I suggest <a href="http://en.wikipedia.org/wiki/Regular_expression"> further reading.</a>

XPath.pm (<xpath> directive)
----------------------------
XPath would retrieve a XML path from XML formatted output.
An example XPath would look like:
{agent}->{"Sample XML extraction"}->{monitor}->{"XML extraction"}->{exectemplate}[0]
Generally speaking you could have a look <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3/config_sample_xpath_extraction.xml>this configuration file</a>.
This mentioned example parses itself (since M3 uses XML configuration files.

JSON.pm (<json> directive)
--------------------------
Very similar to the XPath.pm, this plugin will extract a JSON path.
An example for a JSON path would look like:
<json>{'forecast'}[0]->{'low_temperature'}</json>
