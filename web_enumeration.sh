#!/bin/bash
# Script Name: web_enumeration.sh
# Description: Web enumeration script for user-specified HTTP ports.
# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2025-01-31
# Updated: 2025-02-03
# Version: 1.4

echo ""
echo "WEB ENUMERATION BY SHADOWARC147"
echo ""

# Ensure an IP address is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <IP-ADDRESS> [-p <PORT>]"
  exit 1
fi

TARGET_IP=""
PORT=""

# Parse arguments manually to handle IP as first positional argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) 
      shift
      PORT=$1
      ;;
    *)
      TARGET_IP=$1
      ;;
  esac
  shift
done

# Ensure the IP address is set
if [ -z "$TARGET_IP" ]; then
  echo "Error: No target IP specified."
  exit 1
fi

# If no port is specified, default to 80
if [ -z "$PORT" ]; then
  PORT=80
  echo "[*] No port specified. Defaulting to port 80."
fi

OUTPUT_DIR="http_enum_results_${TARGET_IP}_port${PORT}"
mkdir -p $OUTPUT_DIR

echo "Starting HTTP enumeration for $TARGET_IP on port $PORT..."
echo "Results will be saved in $OUTPUT_DIR"

# Run Gobuster with a larger wordlist
echo "[*] Running Gobuster..."
gobuster dir -u http://$TARGET_IP:$PORT -w /usr/share/wordlists/dirb/big.txt -k -x .txt,.php -o $OUTPUT_DIR/gobuster.txt

# Run Nikto for vulnerability scanning
echo "[*] Running Nikto..."
nikto -h http://$TARGET_IP:$PORT -output $OUTPUT_DIR/nikto_scan.txt

# Run FFUF for fuzzing DNS Discovery
echo "[*] Running FFUF..."
ffuf -k -c -u http://$TARGET_IP:$PORT -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-20000.txt -f>

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
