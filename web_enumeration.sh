#!/bin/bash
# Script Name: web_enumeration.sh
# Description: Enhanced web enumeration script that focuses on HTTP services across multiple ports.
# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2025-01-31
# Updated: 2025-02-03
# Version: 1.1

echo ""
echo "WEB ENUMERATION BY SHADOWARC147"
echo ""

if [ -z "$1" ]; then
  echo "Usage: $0 <IP-ADDRESS> [-p <PORT>]"
  exit 1
fi

TARGET_IP=$1
CUSTOM_PORT=""
OUTPUT_DIR="http_enum_results_$TARGET_IP"
mkdir -p $OUTPUT_DIR

# Check if user provided a custom port
while getopts "p:" opt; do
  case ${opt} in
    p ) CUSTOM_PORT=$OPTARG ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

echo "Starting enhanced HTTP enumeration for $TARGET_IP..."
echo "Results will be saved in $OUTPUT_DIR"

# Run Nmap scan
echo "[*] Running Nmap scan to detect services..."
nmap -sV -sC -oN $OUTPUT_DIR/nmap_initial.txt $TARGET_IP

# Extract all open ports with HTTP services
HTTP_PORTS=$(grep -E "http" $OUTPUT_DIR/nmap_initial.txt | awk -F '/' '{print $1}' | tr '\n' ' ')

# Include user-specified port if provided
if [[ -n "$CUSTOM_PORT" ]]; then
  HTTP_PORTS+=" $CUSTOM_PORT"
fi

if [[ -z "$HTTP_PORTS" ]]; then
  echo "[*] No HTTP services found. Skipping enumeration."
  exit 0
fi

echo "[*] Found HTTP services on ports: $HTTP_PORTS"

# Enumerate each detected HTTP service
for PORT in $HTTP_PORTS; do
  echo "[*] Enumerating HTTP service on port $PORT..."
  
  # Run Gobuster with a larger wordlist
  echo "[*] Running Gobuster..."
  gobuster dir -u http://$TARGET_IP:$PORT -w /usr/share/wordlists/dirb/big.txt -k -x .txt,.php -o $OUTPUT_DIR/gobuster_${PORT}.txt

  # Run Nikto for vulnerability scanning
  echo "[*] Running Nikto..."
  nikto -h http://$TARGET_IP:$PORT -output $OUTPUT_DIR/nikto_${PORT}.txt

  # Run FFUF for fuzzing
  echo "[*] Running FFUF..."
  ffuf -u http://$TARGET_IP:$PORT/FUZZ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o $OUTPUT_DIR/ffuf_${PORT}.json
done

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
