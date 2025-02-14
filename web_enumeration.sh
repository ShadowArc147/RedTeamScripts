#!/bin/bash

# Script Name: web_enumeration.sh
# Description: Web enumeration script with optional tool selection.
# Author: ShadowArc147
# Email: tom.csec0@gmail.com
# Created: 2025-01-31
# Updated: 2025-02-04
# Version: 1.8

echo ""
echo "WEB ENUMERATION BY SHADOWARC147"
echo ""

# Ensure a target is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <IP-ADDRESS or HOSTNAME> [-p <PORT>] [-g] [-n] [-f] [-s] [-a]"
    exit 1
fi

TARGET=""
PORT=""
RUN_GOBUSTER=false
RUN_NIKTO=false
RUN_FFUF=false
RUN_SUBLIST3R=false
RUN_AMASS=false
RUN_ALL=true

# Parse arguments manually to handle target as first positional argument
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p) shift; PORT=$1 ;;
        -g) RUN_GOBUSTER=true; RUN_ALL=false ;;
        -n) RUN_NIKTO=true; RUN_ALL=false ;;
        -f) RUN_FFUF=true; RUN_ALL=false ;;
        -s) RUN_SUBLIST3R=true; RUN_ALL=false ;;
        -a) RUN_AMASS=true; RUN_ALL=false ;;
        *) TARGET=$1 ;;
    esac
    shift
done

# Ensure a target is set
if [ -z "$TARGET" ]; then
    echo "Error: No target specified."
    exit 1
fi

# If no port is specified, default to 80
if [ -z "$PORT" ]; then
    PORT=80
    echo "[*] No port specified. Defaulting to port 80."
fi

# Determine if target is an IP or a domain
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[*] Target appears to be an IP address. Attempting hostname resolution..."
    HOSTNAME=$(nslookup $TARGET | awk '/name =/ {print $4}' | sed 's/\.$//')

    if [ -z "$HOSTNAME" ]; then
        echo "[!] No hostname found for $TARGET. Using the IP directly."
        HOSTNAME=$TARGET
    else
        echo "[*] Resolved hostname: $HOSTNAME"
    fi
else
    echo "[*] Target appears to be a hostname."
    HOSTNAME=$TARGET
fi

OUTPUT_DIR="http_enum_results_${TARGET}_port${PORT}"
mkdir -p $OUTPUT_DIR

echo "Starting HTTP enumeration for $TARGET on port $PORT..."
echo "Results will be saved in $OUTPUT_DIR"

# Run Gobuster if enabled or all tools are selected
if [ "$RUN_GOBUSTER" = true ] || [ "$RUN_ALL" = true ]; then
    echo "[*] Running Gobuster..."
    #gobuster dir -u http://$TARGET:$PORT -w /usr/share/wordlists/dirb/big.txt -k -x .txt,.php,.zip -o $OUTPUT_DIR/gobuster.txt
    gobuster dir -u http://$TARGET:$PORT \
    -w /usr/share/wordlists/dirb/big.txt \
    -k \
    x .txt,.php,.zip,.html,.asp,.aspx,.jsp,.json,.xml,.log,.bak,.tar,.gz,.sql,.config,.ini \
    -wildcard \
    -timeout 10s \
    -exclude-status 404,403 \
    -append-domain \
    -recursive \
    -depth 5 \
    -o $OUTPUT_DIR/gobuster_recursive.txt

fi

# Run Nikto if enabled or all tools are selected
if [ "$RUN_NIKTO" = true ] || [ "$RUN_ALL" = true ]; then
    echo "[*] Running Nikto..."
    nikto -h http://$TARGET:$PORT -output $OUTPUT_DIR/nikto_scan.txt

    # Check if .git is found in Nikto results
    if grep -iq "\.git" $OUTPUT_DIR/nikto_scan.txt; then
        echo "[*] .git directory found in Nikto scan. Attempting to dump the Git repository..."

        # Create a directory for the git dump
        mkdir -p gitdump

        # Download git-dumper.sh and make it executable
        echo "[*] Downloading gitdumper.sh..."
        wget -q https://raw.githubusercontent.com/internetwache/GitTools/master/Dumper/gitdumper.sh -O gitdumper.sh
        chmod +x gitdumper.sh

        # Run git-dumper.sh to dump the .git directory
        echo "[*] Running gitdumper.sh..."
        ./gitdumper.sh http://$TARGET:$PORT/.git/ ./gitdump/

        if [ $? -eq 0 ]; then
            echo "[*] git-dumper successfully dumped the .git directory to ./gitdump/"
        else
            echo "[!] git-dumper failed to dump the .git directory."
        fi

        # Download extractor.sh and make it executable
        echo "[*] Downloading extractor.sh..."
        wget -q https://raw.githubusercontent.com/internetwache/GitTools/master/Extractor/extractor.sh -O extractor.sh
        chmod +x extractor.sh

        # Run extractor.sh to extract the project
        echo "[*] Running extractor.sh..."
        ./extractor.sh ./gitdump/ ./extracted_project/

        if [ $? -eq 0 ]; then
            echo "[*] Git repository successfully extracted to ./extracted_project/"
        else
            echo "[!] Extractor script failed."
        fi
    fi
fi

# Run FFUF without filtering to determine the most common 'Words' value
echo "[*] Running FFUF initial scan to determine wf value..."
ffuf -k -c -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-20000.txt \
    -u "http://$HOSTNAME/" -H "Host: FUZZ.$HOSTNAME" -o $OUTPUT_DIR/ffuf_initial.json

WF_VALUE=$(jq -r '.results[].words' $OUTPUT_DIR/ffuf_initial.json | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
echo "[*] Determined wf value: $WF_VALUE"

echo "[*] Running final FFUF scan with fw=$FW_VALUE..."
ffuf -k -c -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-20000.txt \
    -u "http://$HOSTNAME/" -H "Host: FUZZ.$HOSTNAME" -fw $FW_VALUE \
    -o $OUTPUT_DIR/ffuf_results.json


# Run Amass if enabled or all tools are selected
if [ "$RUN_AMASS" = true ] || [ "$RUN_ALL" = true ]; then
    if command -v amass &> /dev/null; then
        echo "[*] Running Amass..."
        amass enum -d $HOSTNAME -o $OUTPUT_DIR/subdomains.txt
    else
        echo "[*] Amass not found. Skipping..."
    fi
fi

echo "Enumeration complete. Check the $OUTPUT_DIR directory for results."

