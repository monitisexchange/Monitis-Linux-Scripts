## Parsing plugins
 1. LineNumber.pm - &lt;line&gt; - Extract whole line
 2. Regex.pm - &lt;regex&gt; - Regular expression
 3. XPath.pm - &lt;xpath&gt; - XML XPath
 4. JSON.pm - &lt;json&gt; - JSON path

### LineNumber.pm (&lt;line&gt; directive)
Perhaps the simplest parsing plugin M3 has to offer.
This plugin will extract a whole line from the output.
Having for instance the output of:
* * *
Hello
World
* * *
Would result in the following parsing:

 * &lt;line&gt;1&lt;/line&gt; =&gt; Hello
 * &lt;line&gt;2&lt;/line&gt; =&gt; World

### Regex.pm (&lt;regex&gt; directive)
The first and perhaps most powerful parsing plugins M3 has to offer.

Regular expressions are extremely simple yet very powerful and flexible.

Numerous examples exist in the different sample configuration files.

The regex plugin most commonly used feature is to extract the whole output:

&lt;regex&gt;(.&#42;)&lt;/regex&gt;

For instance, extracting the second word in a sentence would be:
* * * 
The __quick__ brown fox jumps over the lazy dog
* * *
 * &lt;regex&gt;\w+\s+(\w+)&lt;/regex&gt; =&gt; __quick__

If you are unfamiliar with regular expressions and would still like to use
them, I suggest <a href="http://en.wikipedia.org/wiki/Regular_expression">further reading</a>.

### XPath.pm (&lt;xpath&gt; directive)
XPath would retrieve a XML path from XML formatted output.

An example XPath would look like:

 * &lt;xpath&gt;{agent}->{"Sample XML extraction"}->{monitor}->{"XML extraction"}->{exectemplate}[0]&lt;/xpath&gt;

Generally speaking you could have a look <a href="https://github.com/monitisexchange/Monitis-Linux-Scripts/blob/master/M3/config_sample_xpath_extraction.xml>this configuration file</a>.

This mentioned example parses itself (since M3 uses XML configuration files.

### JSON.pm (&lt;json&gt; directive)
Very similar to the XPath.pm, this plugin will extract a JSON path.

An example for a JSON path would look like:

&lt;json&gt;{'forecast'}[0]->{'low_temperature'}&lt;/json&gt;
