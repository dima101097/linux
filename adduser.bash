#!/bin/bash

if [ "$(whoami)" != "root" ]; then
    echo "This script must be run as root." >&2
    exit 1
fi
clear
read -p "Enter the new username: " username
if [ -z "$username" ]; then
    echo "Username cannot be empty." >&2
    exit 1
fi
if id "$username" &>/dev/null; then
    echo "User $username already exists." >&2
    exit 1
fi
while true; do
    read -s -p "Enter the password: " password
    echo
    read -s -p "Confirm the password: " password_confirm
    echo
    if [ "$password" == "$password_confirm" ]; then
        break
    else
        echo "Passwords do not match. Try again." >&2
    fi
done
useradd -m -s /bin/bash "$username"
echo "$username:$password" | chpasswd
usermod -aG sudo "$username"
if passwd -S root | grep -q 'PS'; then
    echo "Root is already disabled."
else
    echo "Disabling root"
    passwd -l root
fi

exit