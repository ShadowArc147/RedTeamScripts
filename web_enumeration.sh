#!/bin/bash
# Script Name: web_enumeration.sh
# Description: Enhanced web enumeration script for user-specified HTTP ports.
# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2025-01-31
# Updated: 2025-02-03
# Version: 1.2

echo ""
echo "WEB ENUMERATION BY SHADOWARC147"
echo ""

if [ -z "$1" ]; then
  echo "Usage: $0 <IP-ADDRESS> [-p <PORT>]"
  exit 1
fi

TARGET_IP=$1
PORT=80  # Default to port 80

# Parse optional port argument
while getopts "p:" opt; do
  case ${opt} in
    p ) PORT=$OPTARG ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

OUTPUT_DIR="http_enum_results_${TARGET_IP}_port${PORT}"
mkdir -p $OUTPUT_DIR

echo "Starting HTTP enumeration for $TARGET_IP on port $PORT..."
echo "Results will be saved in $OUTPUT_DIR"

# Run Nmap scan
echo "[*] Running Nmap scan..."
nmap -sV -sC -p $PORT -oN $OUTPUT_DIR/nmap_scan.txt $TARGET_IP

# Run Gobuster with a larger wordlist
echo "[*] Running Gobuster..."
gobuster dir -u http://$TARGET_IP:$PORT -w /usr/share/wordlists/dirb/big.txt -k -x .txt,.php -o $OUTPUT_DIR/gobuster.txt

# Run Nikto for vulnerability scanning
echo "[*] Running Nikto..."
nikto -h http://$TARGET_IP:$PORT -output $OUTPUT_DIR/nikto_scan.txt

# Run FFUF for fuzzing
echo "[*] Running FFUF..."
ffuf -u http://$TARGET_IP:$PORT/FUZZ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o $OUTPUT_DIR/ffuf_results.json

# Domain and DNS Enumeration
echo "[*] Performing DNS and domain enumeration..."
nslookup $TARGET_IP > $OUTPUT_DIR/nslookup.txt
dig $TARGET_IP ANY > $OUTPUT_DIR/dig_results.txt

# Check for Subdomain Enumeration tools
if command -v sublist3r &> /dev/null; then
  echo "[*] Running Sublist3r..."
  sublist3r -d $TARGET_IP -o $OUTPUT_DIR/subdomains.txt
elif command -v amass &> /dev/null; then
  echo "[*] Running Amass..."
  amass enum -d $TARGET_IP -o $OUTPUT_DIR/subdomains.txt
else
  echo "[*] No subdomain enumeration tools found (Sublist3r/Amass). Skipping..."
fi

echo "Enumeration complete. Check the $OUTPUT_DIR directory for results."
