#!/usr/bin/env python3
import os
import subprocess
import re
import requests

# ANSI Colours
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RESET = "\033[0m"

# Check BloodHound version
def check_bloodhound_version():
    print(f"{YELLOW}[*] Checking installed BloodHound version...{RESET}")
    try:
        result = subprocess.check_output("bloodhound --version", shell=True, text=True)
        version = re.search(r"\d+\.\d+\.\d+", result)
        if version:
            return version.group(0)
    except subprocess.CalledProcessError:
        print(f"{RED}[!] BloodHound not found. Installing...{RESET}")
        install_bloodhound()
        return check_bloodhound_version()
    return None

# Install BloodHound if missing
def install_bloodhound():
    print(f"{YELLOW}[*] Installing BloodHound from GitHub...{RESET}")
    run_cmd("wget https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-linux-x64.zip -O BloodHound.zip")
    run_cmd("unzip BloodHound.zip -d /opt/BloodHound")
    run_cmd("ln -s /opt/BloodHound/BloodHound /usr/bin/bloodhound")
    print(f"{GREEN}[+] BloodHound installed!{RESET}")

# Find compatible SharpHound/BloodHound-python version
def get_compatible_collector(bh_version):
    print(f"{YELLOW}[*] Finding compatible SharpHound version for BloodHound {bh_version}...{RESET}")
    compatibility_map = {
        "4.0.0": "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe",
        "4.1.0": "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe",
        "4.2.0": "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe",
        "4.3.0": "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe",
        "4.4.0": "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe",
        "4.5.0": "https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe"
    }

    closest_version = max(compatibility_map.keys(), key=lambda v: v if v <= bh_version else "0.0.0")
    collector_url = compatibility_map.get(closest_version)

    if collector_url:
        print(f"{GREEN}[+] Compatible SharpHound found: {closest_version}{RESET}")
        return collector_url
    else:
        print(f"{RED}[!] No compatible SharpHound found. Using default.{RESET}")
        return compatibility_map["4.0.0"]

# Download and configure SharpHound
def setup_sharphound(collector_url):
    print(f"{YELLOW}[*] Downloading SharpHound...{RESET}")
    run_cmd(f"wget {collector_url} -O /opt/BloodHound/SharpHound.exe")
    print(f"{GREEN}[+] SharpHound setup complete!{RESET}")

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

# Main logic
if __name__ == "__main__":
    bloodhound_version = check_bloodhound_version()
    if bloodhound_version:
        print(f"{GREEN}[+] BloodHound Version: {bloodhound_version}{RESET}")
        collector_url = get_compatible_collector(bloodhound_version)
        setup_sharphound(collector_url)
    else:
        print(f"{RED}[!] BloodHound installation failed. Check manually.{RESET}")
