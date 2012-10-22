# apache-log-parser.py

This is a Python script and command-line tool,
with no dependencies, that allows parsing data
from Apache log files.

Its main purpose is to be use with Monitis Monitoring,
but it should be possible to use it standalone.

## Options

-r, --resolution    : define time resolution (e.g. 1 sec = sec) can be sec, min, hour, day
-m, --measure       : define what to measurement (predefine HTTP responses, groups of responses and requests)
but it also cand be easily define for uri, ip address, referral or agent string.,
    Prefine responses (status codes) are in range: 200, 201, 202, 203, 204, 205, 206, 300, 301, 302, 303, 304, 305, 306, 307, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 500, 501, 502, 503, 504, 505.
    Predefine group or resources (2XX, 3XX, 4XX, 5XX) using above status codes.
    Prefine requests are: GET, POST, OPTIONS, PATCH, PUT, HEAD, CONNECT, DELETE, TRACE.
-t, --time          : define how to print time in output - apache - DD/MMM/YYYY, unix - unix timestamp.



## Credits
This script original comes from:
https://github.com/lethain/apache-log-parser
