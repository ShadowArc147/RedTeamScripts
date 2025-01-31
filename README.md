# RedTeamScripts
Collection of useful scripts I've made to aid in Red Team activities

# Simple Enumeration
This script is a collection of commands mainly used when enumerating a box. It combines NMAP, Gobuster, SNMP, FTP, CVE detection etc etc...

For example, if the initial NMAP enum returns port 21, it will automatically attempt an anonymous login. If it finds a HTTP service running on port 80, it'll automatically run Gobuster and Nikito.

Usage: sudo ./simple_enumeration <targetIP>
Usage: sudo ./simple_enumeration <targetIP, targetIP2, targetIP3, etc etc>


# Web Enumeration
This is a version of Simple Enumeration that focuses on port 80. It swaps out the smaller, quicker wordlist for something a bit more substantial and performs additional DNS, Domain and Subdomain enumeration.


Have fun!

