#!/bin/bash
# Script Name:ftp_grab.sh
# Description:
# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2024-11-11
# Updated: 2024-12-29
# Version: 1.1
# Usage: ftp_grab <IP>
# Enhanced FTP Enumeration Script
# Focused on FTP (Port 21) with anonymous login detection and file retrieval

if [ -z "$1" ]; then
  echo "Usage: $0 <IP-ADDRESS>"
  exit 1
fi

TARGET_IP=$1
OUTPUT_DIR="ftp_enum_results_$TARGET_IP"
mkdir -p $OUTPUT_DIR

echo "Starting enhanced FTP enumeration for $TARGET_IP..."
echo "Results will be saved in $OUTPUT_DIR"

# Run Nmap scan
nmap -sV -sC -oN $OUTPUT_DIR/nmap_initial.txt $TARGET_IP

# Check for FTP on Port 21
if grep -q "21/tcp" $OUTPUT_DIR/nmap_initial.txt; then
  echo "[*] FTP detected on port 21. Checking for anonymous login..."

  # Check if anonymous login is allowed
  if echo -e "open $TARGET_IP\nuser anonymous anonymous\nquit" | ftp -n 2>&1 | grep -q "230 Login successful"; then
    echo "[*] Anonymous FTP login allowed. Listing files..."
    echo -e "open $TARGET_IP\nuser anonymous anonymous\nls\nquit" | ftp -n > $OUTPUT_DIR/ftp_file_list.txt

    echo "[*] Attempting to download all files..."
    echo -e "open $TARGET_IP\nuser anonymous anonymous\nprompt off\nmget *\nquit" | ftp -n >> $OUTPUT_DIR/ftp_download_log.txt
    mv * $OUTPUT_DIR/ 2>/dev/null
  else
    echo "[*] Anonymous login not allowed. Skipping file retrieval."
  fi
else
  echo "[*] No FTP service found on port 21. Skipping FTP enumeration."
fi

echo "Enumeration complete. Check the $OUTPUT_DIR directory for results."