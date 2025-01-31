#!/bin/bash
# Script Name:simple_enumeration.sh
# Description: An all in one local script that combines multiple elements of simple enumeration against a single IP and saves results to disk
# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2024-11-11
# Updated: 2024-12-29
# Version: 1.1
# Usage: simple_enumeration <IP>

echo ""
echo "SIMPLE ENUMERATION BY SHADOWARC147"
echo ""
echo "/////////////////////////////////////////////////////////////////"
echo "LOOK OUT FOR THE FOLLOWING PORTS/RESULTS"
echo "HTTP: Could potentially host a web application where you can find vulnerabilities like SQL injection or Remote Code Execution (RCE)." 
echo "FTP: Could allow anonymous login and provide access to interesting files." 
echo "SMB: Could be vulnerable to SMB exploits like MS17-010"
echo "SSH: Could have default or easy to guess credentials"
echo "RDP: Could be vulnerable to Bluekeep or allow desktop access if weak credentials were used." 
echo "/////////////////////////////////////////////////////////////////"

if [ -z "$1" ]; then
  echo "Usage: $0 <IP-ADDRESS>"
  exit 1
fi

TARGET_IP=$1
OUTPUT_DIR="enum_results_$TARGET_IP"
mkdir -p $OUTPUT_DIR

echo "Starting enumeration for $TARGET_IP..."
echo "Results will be saved in $OUTPUT_DIR"
echo

# Run Nmap scans
echo "[*] Running initial Nmap scan..."
nmap -sV -sC -oN $OUTPUT_DIR/nmap_initial.txt $TARGET_IP

echo "[*] Running full TCP port scan with Nmap..."
nmap -p- -oN $OUTPUT_DIR/nmap_full_tcp.txt $TARGET_IP

echo "[*] Running Nmap UDP scan (this may take a while)..."
nmap -sU --top-ports 100 -oN $OUTPUT_DIR/nmap_udp.txt $TARGET_IP

echo

# Service-specific enumeration
# Check for SMB
echo "[*] Checking for SMB shares and version..."
nmap --script smb-enum-shares,smb-enum-users -p 139,445 -oN $OUTPUT_DIR/nmap_smb_enum.txt $TARGET_IP
enum4linux -a $TARGET_IP > $OUTPUT_DIR/enum4linux.txt

# Check for HTTP services
echo "[*] Checking for HTTP services..."
HTTP_PORTS=$(grep "http" $OUTPUT_DIR/nmap_initial.txt | grep -oP '\d+/tcp' | cut -d '/' -f1 | tr '\n' ',' | sed 's/,$//')
if [ ! -z "$HTTP_PORTS" ]; then
  echo "  - Found HTTP services on ports: $HTTP_PORTS"
  echo "  - Running Nikto and Gobuster..."
  for PORT in $(echo $HTTP_PORTS | tr ',' ' '); do
    nikto -h http://$TARGET_IP:$PORT -output $OUTPUT_DIR/nikto_$PORT.txt
    gobuster dir -u http://$TARGET_IP:$PORT -w /usr/share/wordlists/dirb/common.txt -o $OUTPUT_DIR/gobuster_$PORT.txt
  done
else
  echo "  - No HTTP services found."
fi

# Check for FTP service
echo "[*] Checking for FTP..."
if grep -q "21/tcp" $OUTPUT_DIR/nmap_initial.txt; then
  echo "  - FTP detected. Attempting anonymous login..."
  echo "quit" | ftp -inv $TARGET_IP > $OUTPUT_DIR/ftp_anonymous.txt
else
  echo "  - No FTP service found."
fi

# Check for SSH service
echo "[*] Checking for SSH..."
if grep -q "22/tcp" $OUTPUT_DIR/nmap_initial.txt; then
  echo "  - SSH detected. Gathering SSH version info..."
  ssh -oBatchMode=yes $TARGET_IP "exit" 2>&1 | tee $OUTPUT_DIR/ssh_version.txt
else
  echo "  - No SSH service found."
fi

# Running default vulnerability scans
echo "[*] Running vulnerability scans using Nmap scripts..."
nmap --script vuln -oN $OUTPUT_DIR/nmap_vuln_scan.txt $TARGET_IP

echo
echo "Enumeration complete. Check the $OUTPUT_DIR directory for results."
