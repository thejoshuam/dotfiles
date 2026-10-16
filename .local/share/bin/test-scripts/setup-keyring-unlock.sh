#!/usr/bin/env bash

#Mon Sep 14 09:57:57 AM ACST 2026
#
# Standalone scriptlet extracted from the Omarchy 4.0 post-install script.
# Runs ONLY the keyring-unlock setup:
#   - creates /etc/keyring_secret (root:root 0600) if missing
#   - installs unlock-keyring-secure.sh to /usr/local/sbin
#   - creates + enables keyring-unlock-root.service
#   - prints the manual Seahorse steps and waits for you to read them
#
# Run from the dotfiles repo root (or anywhere, so long as DOTFILES below
# points at your dotfiles checkout).

set -u

DOTFILES="/home/j/Documents/_git/dotfiles"
DOTFILES_BIN="$DOTFILES/.local/share/bin"

KEYRING_UID="$(id -u)"
KEYRING_USER="$(id -un)"
KEYRING_SCRIPT_SRC="$DOTFILES_BIN/unlock-keyring-secure.sh"
KEYRING_SCRIPT_DST="/usr/local/sbin/unlock-keyring-secure.sh"
KEYRING_UNIT="/etc/systemd/system/keyring-unlock-root.service"
KEYRING_SECRET="/etc/keyring_secret"

printf '%s\n' "Keyring-unlock setup for UID $KEYRING_UID ($KEYRING_USER)"
printf '%s\n' "Dotfiles: $DOTFILES"
printf '\n'

# 1. Create the shared secret, if it doesn't already exist.
if [ ! -f "$KEYRING_SECRET" ]; then
  sudo sh -c 'umask 077; openssl rand -base64 32 > /etc/keyring_secret' \
    && sudo chmod 600 "$KEYRING_SECRET" \
    && sudo chown root:root "$KEYRING_SECRET" \
    && printf '%s\n' "Created $KEYRING_SECRET (root:root 0600)"
else
  printf '%s\n' "$KEYRING_SECRET already exists; leaving it."
fi

# 2. Install the unlock helper script (from the repo, or a fallback copy).
if [ -f "$KEYRING_SCRIPT_SRC" ]; then
  sudo install -D -m 755 "$KEYRING_SCRIPT_SRC" "$KEYRING_SCRIPT_DST"
else
  printf '%s\n' "unlock-keyring-secure.sh missing from repo; writing a copy to $KEYRING_SCRIPT_DST"
  sudo tee "$KEYRING_SCRIPT_DST" > /dev/null <<'KEYRING_EOF'
SECRET_FILE="/etc/keyring_secret"
USER_UID="${KEYRING_UID:-1000}"
TARGET_USER="$(getent passwd "$USER_UID" | cut -d: -f1)"
if [ -z "$TARGET_USER" ] || [ ! -f "$SECRET_FILE" ] || [ ! -d "/run/user/$USER_UID" ]; then
  echo "keyring unlock preconditions failed" >&2
  exit 1
fi
runuser -u "$TARGET_USER" -- env XDG_RUNTIME_DIR="/run/user/$USER_UID" \
  gnome-keyring-daemon --unlock < "$SECRET_FILE"
KEYRING_EOF
  sudo chmod 755 "$KEYRING_SCRIPT_DST"
fi

# 3. Create and enable the systemd unit that runs the helper at boot.
sudo tee "$KEYRING_UNIT" > /dev/null <<EOF
[Unit]
Description=Unlock User Keyring via Root File
After=user-runtime-dir@${KEYRING_UID}.service
Requires=user-runtime-dir@${KEYRING_UID}.service

[Service]
Type=oneshot
ExecStart=$KEYRING_SCRIPT_DST
Environment=KEYRING_UID=${KEYRING_UID}
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable keyring-unlock-root.service
printf '%s\n' "Enabled keyring-unlock-root.service for UID $KEYRING_UID ($KEYRING_USER)"

# 4. Manual Seahorse steps + prompt (unchanged from the original script).
cat <<EOF

========================================================================
Manual steps — encrypt the Login keyring (do this before reboot)
------------------------------------------------------------------------
Omarchy autologin cannot PAM-unlock an encrypted keyring. Seahorse has
been installed. The boot unlock service is enabled; you still have to
point the Login keyring at /etc/keyring_secret once.

  1. Copy the secret:
       sudo cat /etc/keyring_secret

  2. Open Passwords and Keys (Seahorse).

  3. There must be a keyring named exactly "Login" (not "Default Keyring").
     Create it if missing, then: right-click Login → Set as Default
     (or: printf 'Login\\n' > ~/.local/share/keyrings/default)

  4. Right-click Login → Change Password
       Old password: blank (Omarchy default)
       New password: paste the secret from step 1

  5. After reboot, if prompted to unlock: paste the secret again and
     tick autounlock / "Unlock with login password".

Source:
https://github.com/omacom/omarchy/discussions/3331#discussioncomment-15247393
========================================================================

EOF

printf 'Press Enter after reading the Seahorse steps (or to continue)... '
IFS= read -r _ || true

printf '%s\n' "Keyring-unlock setup complete."
