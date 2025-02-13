#!/bin/bash

# Ult-Buster: Recursive Gobuster Automation
# Usage: ./ult-buster.sh http://target.com

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target-URL>"
    exit 1
fi

TARGET=$1
WORDLIST="/usr/share/wordlists/dirb/big.txt"
EXCLUDE_EXT="txt|pdf|zip|php|ico|jpg|png|css|js|gif|mp4|mp3|svg|json"

# Array to hold directories to scan
declare -a DIR_QUEUE
DIR_QUEUE+=("$TARGET")

# Function to scan a directory
scan_directory() {
    local dir=$1
    echo "[+] Scanning: $dir"
    
    # Run Gobuster and filter results (only 200 status & directories)
    results=$(gobuster dir -u "$dir" -w "$WORDLIST" -q -o temp_scan.txt)
    
    # Extract directories while filtering out unwanted file extensions
    new_dirs=$(grep "Status: 200" temp_scan.txt | awk '{print $2}' | grep -Ev "\.($EXCLUDE_EXT)")
    
    # Add new directories to the queue
    for new_dir in $new_dirs; do
        full_path="$dir/$new_dir"
        if [[ ! " ${DIR_QUEUE[@]} " =~ " $full_path " ]]; then
            DIR_QUEUE+=("$full_path")
        fi
    done
}

# Recursive Loop through directories in the queue
index=0
while [ $index -lt ${#DIR_QUEUE[@]} ]; do
    scan_directory "${DIR_QUEUE[$index]}"
    ((index++))
done

rm -f temp_scan.txt  # Cleanup

echo "[+] Ult-Buster Scan Completed!"
