#!/usr/bin/env bash

# Keychain service identifier for your app
SERVICE_NAME="my_shell_script"

register() {
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

login() {
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
    else
        echo "Error: Incorrect password."
    fi
}

main() {
    echo "Press 1 to create new user or 2 to log in:"
    read -p "Choice: " LOGNUM

    if [ "$LOGNUM" -eq 1 ]; then
        register
    elif [ "$LOGNUM" -eq 2 ]; then
        login
    else
        echo "Invalid choice."
        main
    fi
}

main
