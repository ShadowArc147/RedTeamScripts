# RedTeamScripts
Collection of useful scripts I've made to aid in Red Team activities

# Simple Enumeration
This script is a collection of commands mainly used when enumerating a box. It combines NMAP, Gobuster, SNMP, FTP, CVE detection etc etc...

For example, if the initial NMAP enum returns port 21, it will automatically attempt an anonymous login. If it finds a HTTP service running on port 80, it'll automatically run Gobuster and Nikito.

Have fun!

