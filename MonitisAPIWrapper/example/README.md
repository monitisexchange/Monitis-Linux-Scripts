## Twitter users monitor ##

This project intended to be a sample of using Monitis Open API wrapper which implemented wholly on Linux Bash Script.  
The current monitor tracks for extended information of specified Twitter user, specified by screen name or user id.  
It uses the some part of [Twitter REST API](https://dev.twitter.com/docs/api) and [Monitis Open API](http://monitis.com/api/api.html) to grab data from Twitter and send it into the Monitis.  
The monitor works without any authentication procedure because it monitors for unprotected users only.  

To try it you have to do the following:

   - copy all scripts from _api_ and _example_ folders into one folder
   - change __"secret key"__ and __"api key"__ in the __monitis_constant.sh__ script according your monitis account
   - start the monitor by the following command

        mon_start.sh -i <user ID> -s <user screen name> -d <duration in min>

   __Note__: One of "User screen name" or "user id" should be specified. If both are specified, "User screen name" is preferable and will used although "user id" is specified also.

   The default values for "duration" parameters is defined as 30 min.

The current implementation measures the following parameters

   - followers_count     The number of followers the author of the original Tweet has on Twitter
   - friends_count       The number of people the user follows on Twitter
   - listed_count        The number of Twitter lists that the author of this Tweet appears on
   - favourites_count    The number of Tweets that given user has marked as favorite
   - statuses_count      The total number of Tweets and Retweets the Twitter user has posted.

You can see below the screenshot of monitor test for Monitis user 

<a href="http://i.imgur.com/ld98K"><img src="http://i.imgur.com/ld98K.png" title="Twitter monitis monitoring test" /></a>

By double clicking you can see additional information

<a href="http://i.imgur.com/4wWeG"><img src="http://i.imgur.com/4wWeG.png" title="Twitter monitis monitoring test" /></a>
