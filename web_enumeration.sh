#!/bin/bash
# Script Name:web_enumeration.sh
# Description: This is a version of Simple Enumeration that focuses on port 80. It swaps out the smaller, quicker wordlist for something a bit more substantial and performs additional DNS, Domain and Subdomain enumeration.# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2025-01-31
# Updated:
# Version: 1.0
# Usage: web_enumeration <IP>
# Enhanced HTTP Enumeration Script
# Focused on HTTP (Port 80) with deeper scanning and DNS/Domain enumeration

echo ""
echo "WEB ENUMERATION BY SHADOWARC147"
echo ""


if [ -z "$1" ]; then
  echo "Usage: $0 <IP-ADDRESS>"
  exit 1
fi

TARGET_IP=$1
OUTPUT_DIR="http_enum_results_$TARGET_IP"
mkdir -p $OUTPUT_DIR

echo "Starting enhanced HTTP enumeration for $TARGET_IP..."
echo "Results will be saved in $OUTPUT_DIR"

# Run Nmap scan
nmap -sV -sC -oN $OUTPUT_DIR/nmap_initial.txt $TARGET_IP

# Check for HTTP on Port 80
if grep -q "80/tcp" $OUTPUT_DIR/nmap_initial.txt; then
  echo "[*] HTTP detected on port 80. Running deeper enumeration..."

  # Run Gobuster with a larger wordlist
  echo "[*] Running Gobuster with big.txt wordlist..."
  gobuster dir -u http://$TARGET_IP -w /usr/share/wordlists/dirb/big.txt -o $OUTPUT_DIR/gobuster_big.txt

  # Run Nikto for vulnerability scanning
  echo "[*] Running Nikto scan..."
  nikto -h http://$TARGET_IP -output $OUTPUT_DIR/nikto_scan.txt

  # Domain and DNS Enumeration
  echo "[*] Performing DNS and domain enumeration..."
  nslookup $TARGET_IP > $OUTPUT_DIR/nslookup.txt
  dig $TARGET_IP ANY > $OUTPUT_DIR/dig_results.txt
  
  # Check for Subdomain Enumeration tools
  if command -v sublist3r &> /dev/null; then
    echo "[*] Running Sublist3r for subdomain enumeration..."
    sublist3r -d $TARGET_IP -o $OUTPUT_DIR/subdomains.txt
  elif command -v amass &> /dev/null; then
    echo "[*] Running Amass for subdomain enumeration..."
    amass enum -d $TARGET_IP -o $OUTPUT_DIR/subdomains.txt
  else
    echo "[*] No subdomain enumeration tools found (Sublist3r/Amass). Skipping..."
  fi
else
  echo "[*] No HTTP service found on port 80. Skipping HTTP enumeration."
fi

echo "Enumeration complete. Check the $OUTPUT_DIR directory for results."