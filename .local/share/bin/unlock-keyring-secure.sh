#!/bin/bash

## From stack github issue on Omarchy (basecamp) issue:
## https://web.archive.org/web/20260409014809/https://github.com/basecamp/omarchy/discussions/3331#discussioncomment-15247393
## THIS script fell over. Gnome keyring directly not seeming to work.
## slightly temporary workaround below.
## https://github.com/basecamp/omarchy/issues/4302

# Define your user and UID (1000 is the most common)
TARGET_USER="joshuamiller"
USER_UID=1000
SECRET_FILE="/etc/keyringsecret"

# 1. Read the password from the locked-down file
# Only root can run this script, and only root can read that file.
if [ -f "$SECRET_FILE" ]; then
    PASS=$(cat "$SECRET_FILE")
else
    echo "Keyring secret file not found!"
    exit 1
fi

# 2. Inject into the user's keyring daemon
if [ -n "$PASS" ]; then
    runuser -u "$TARGET_USER" -- env XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    sh -c "echo -n '$PASS' | gnome-keyring-daemon --unlock"
fi

# attempted to rewrite script in dash; have restored
## 1. Read the password from the locked-down file
## Only root can run this script, and only root can read that file.
#if [ -f "$SECRET_FILE" ]; then
#    PASS=$(cat "$SECRET_FILE")
#else
#    echo "Keyring secret file not found!"
#    exit 1
#fi
#
## 2. Inject into the user's keyring daemon
#if [ -n "$PASS" ]; then
#    runuser -u "$TARGET_USER" -- env XDG_RUNTIME_DIR="/run/user/$USER_UID" \
#    bash -c "echo -n '$PASS' | gnome-keyring-daemon --unlock"
#fi
