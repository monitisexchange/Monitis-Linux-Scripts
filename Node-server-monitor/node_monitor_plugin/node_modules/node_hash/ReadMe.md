#node_hash - a super simple hashing library for node.js
## supports md5, sha1, sha256, sha512, ripemd160

<img border = "0" src = "https://github.com/Marak/node_hash/raw/master/logo.jpg"/>

##what is a hash?

a "hash algorithm" is a one-way mathematical equation that takes in an arbitrary length input and produces a fixed length output string.	the output of this algorithm is called a "hash value" and is a unique and extremely compact numerical representation of the original input.

##why bother hashing?

there are many reasons for hashing and many detailed explanations on the web. i'll illustrate one very simple example and why I am currently using this library. 

imagine you had a database that stored user accounts with passwords. anyone who got access to your database, would have access to the passwords of all your users. many people utilize the same password across many services, so their entire online identity could be compromised. 

even if you have your database fully protected from outside intruders, you can still be at risk. imagine you were running a development shop and required a minor schema change for your users table. this task could be delegated to a junior developer or contractor, but since your passwords are stored in plain text you've just given the passwords of your entire user base to a low-level employee.

##how would hashing help this problem?

instead of storing your user's password as plaintext, you could perform a hash on the password before being storing it in your database. 

now, instead of seeing a human readable format, you will see an obfuscated string representing the hash of your password. 

everytime you want to check if a value matches that hash (in this case, perhaps a login form handler), you can simply call the same hashing method on that value and compare it to the value in your database. if the hashes match, the passwords match.

you can also provide an optional "salt" that will further encrypt your password, making it even harder to reverse / crack. you should use a unique salt for every password and store that salt.

##usage

      var sys = require('sys'), 
      hash = require('./lib/hash');

      // a user's password, hash this please
      var user_password = "password";

      // don't expose your salt ( you should use a new salt for every password )
      var salt = "sUp3rS3CRiT$@lt";


      /****** md5 ******/
      var md5 = hash.md5(user_password);
      sys.puts(md5);

      var salted_md5 = hash.md5(user_password, salt);
      sys.puts(salted_md5);

      /****** sha1 ******/
      var sha1 = hash.sha1(user_password);
      sys.puts(sha1);

      var salted_sha1 = hash.sha1(user_password, salt);
      sys.puts(salted_sha1);

      /****** sha256 ******/
      var sha256 = hash.sha256(user_password);
      sys.puts(sha256);

      var salted_sha256 = hash.sha256(user_password, salt);
      sys.puts(salted_sha256);

      /****** sha512 ******/
      var sha512 = hash.sha512(user_password);
      sys.puts(sha512);

      var salted_sha512 = hash.sha512(user_password, salt);
      sys.puts(salted_sha512);

      /****** ripemd160 ******/
      var ripemd160 = hash.ripemd160(user_password);
      sys.puts(ripemd160);

      var salted_ripemd160 = hash.ripemd160(user_password, salt);
      sys.puts(salted_ripemd160);

## faq
**why not use the node.js <a href = "http://nodejs.org/api.html#crypto-236">crypto library</a> instead?**

*node_hash DOES use the built in node.js <a href = "http://nodejs.org/api.html#crypto-236">crypto</a> library, we are just wrapping it for easy use*

**why doesn't node_hash do X (binary, base64, streaming, etc)?**

*node_hash is meant as a very simple  library for hashing text with optional salts in the most common encryption algorithms. if you need finer tuned control, you should be using the <a href = "http://nodejs.org/api.html#crypto-236">crypto</a> module directly*