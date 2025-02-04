# RedTeamScripts
Collection of useful scripts I've made to aid in Red Team activities

# Simple Enumeration
This script is a collection of commands mainly used when enumerating a box. It combines NMAP, Gobuster, SNMP, FTP, CVE detection etc etc...

For example, if the initial NMAP enum returns port 21, it will automatically attempt an anonymous login. If it finds a HTTP service running on port 80, it'll automatically run Gobuster and Nikito.

Usage: sudo ./simple_enumeration <targetIP>
Usage: sudo ./simple_enumeration <targetIP, targetIP2, targetIP3, etc etc>


# Web Enumeration
This is a version of Simple Enumeration that focuses on port 80. It swaps out the smaller, quicker wordlist for something a bit more substantial and performs additional DNS, Domain and Subdomain enumeration.

# Injection Checker
This is good if you're faced with a login page and you can't quite remember the right syntax to see if its vulnerable to basic SQL Injection. This code will make a HTML copy of the page, find the interactable sections of the page (username/password) and then attempt to login with incorrect creds. The code makes not of the size of the page under normal conditions and then attempts the following:

"' OR '1'='1", 
"' OR '1'='1' -- ",
"' OR '1'='1' #",
"admin' -- ",
"admin' #",
"admin' OR '1'='1",
"admin' OR '1'='1' -- "

If any of these attempts returns a page size that's different to the baseline size, its vulnerable to SQL Injection!

Have fun!

