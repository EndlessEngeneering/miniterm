#!/usr/bin/env bash

# Keychain service identifier for your app
SERVICE_NAME="miniterm_auth"

# Dynamically locate the folder where miniterm is installed
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

register_user() {
    echo "=== Create New User ==="
    read -p "User: " NewUser
    read -p "Password: " -s NewPassword
    echo ""

    if [ -z "$NewUser" ] || [ -z "$NewPassword" ]; then
        echo "Error: Username and password cannot be empty."
        return
    fi

    # -a: account name, -s: service name, -w: password, -U: update if already exists
    security add-generic-password -a "$NewUser" -s "$SERVICE_NAME" -w "$NewPassword" -U 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "User '$NewUser' successfully registered and saved to macOS Keychain!"
    else
        echo "Failed to save user credentials."
    fi
}

login_user() {
    echo "=== Log In ==="
    read -p "User: " LOGINUSER
    read -p "Password: " -s LOGINPASSWORD
    echo ""

    # Fetch stored password for the given account from Keychain
    SAVED_PASSWORD=$(security find-generic-password -a "$LOGINUSER" -s "$SERVICE_NAME" -w 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "Error: User '$LOGINUSER' not found."
        return
    fi

    # Verify input password against the stored password
    if [ "$LOGINPASSWORD" = "$SAVED_PASSWORD" ]; then
        echo "Login successful! Welcome, $LOGINUSER."
        # This returns 0 (success) so the main menu knows authentication passed
        return 0 
    else
        echo "Error: Incorrect password."
        return 1
    fi
}

run_scanner() {
    echo "Starting Scan Application..."
    # Safely point to the scan.sh file inside your APPS folder
    if [ -f "$BASE_DIR/APPS/scan.sh" ]; then
        bash "$BASE_DIR/APPS/scan.sh"
    else
        echo "Error: APPS/scan.sh not found at $BASE_DIR/APPS/scan.sh"
    fi
}

show_app_menu() {
    echo ""
    echo "================================="
    echo "    MINITERM APPLICATION MENU    "
    echo "================================="
    echo "Select an application to run:"
    echo ""

    # Define menu choices
    apps=("Scan System" "Create New User Account" "Exit Menu")

    select choice in "${apps[@]}"; do
        case $REPLY in
            1)
                run_scanner
                break
                ;;
            2)
                register_user
                break
                ;;
            3)
                echo "Exiting miniterm. Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid selection. Please choose a number from the list."
                ;;
        esac
    done
}

main() {
    echo "Welcome to Miniterm!"
    echo "Press 1 to log in or 2 to register a new account:"
    read -p "Choice: " LOGNUM

    if [ "$LOGNUM" -eq 1 ]; then
        # If login returns 0 (success), open up the main app selection menu
        if login_user; then
            while true; do
                show_app_menu
            done
        fi
    elif [ "$LOGNUM" -eq 2 ]; then
        register_user
        main # Send them back to the login screen after registering
    else
        echo "Invalid choice."
        main
    fi
}

# Run the program
main
