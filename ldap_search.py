import argparse
import os
import lib.host as Host


def run_ldap_query(distinguished_name: str, target: str, output_file: str = "ldap_search_result.txt") -> str:
    """
    Executes an LDAP search query against the specified target.

    Args:
        distinguished_name (str): The base DN for the LDAP search.
        target (str): The LDAP server to query.
        output_file (str): File to save the results.

    Returns:
        str: The result of the LDAP query.
    """
    command = ["ldapsearch", "-x", "-b", distinguished_name, "*", f"-H ldap://{target}"]
    
    print(f"[*] Running LDAP search against {target} with base DN '{distinguished_name}'...")
    result = Host.executeShellScript(command)

    if result[0] == 0:
        print(f"[+] LDAP search successful! Results saved to {output_file}")
        with open(output_file, "w") as f:
            f.write(result[1])
        return result[1]  # Return for programmatic use
    else:
        print("[-] LDAP search failed.")
        print("STDOUT:", result[1])
        print("STDERR:", result[2])
        return f"ERROR: {result[2]}"


def main():
    parser = argparse.ArgumentParser(description="Perform an LDAP search against a specified target.")
    parser.add_argument("distinguished_name", help="The base DN for the LDAP search (e.g., dc=htb,dc=local)")
    parser.add_argument("target", help="The LDAP server IP or hostname to query")
    parser.add_argument("-o", "--output", help="Output file for saving results", default="ldap_search_result.txt")

    args = parser.parse_args()
    
    run_ldap_query(args.distinguished_name, args.target, args.output)


if __name__ == "__main__":
    main()
