#!/usr/bin/env bash
# Omarchy post-install script Version 2 — run from the dotfiles repo root
#
#         v   don't forget to
#                 update 
# Version 2.0         that
#                 version
#         ^           number
#
# 4.0 ships an ALPM pre-transaction guard that aborts raw pacman
# (especially -Syu). Bypass it the documented way:
#   sudo env OMARCHY_ALLOW_DIRECT_PACMAN=1 pacman ...
# sudo strips the environment, so every privileged pacman call carries
# the flag explicitly. yay is invoked with --sudoflags so the same
# flag survives into the pacman child.
#
# Installers are non-interactive. Repo/AUR installs go through
# omarchy-pkg-add / omarchy-pkg-aur-add (same as the Omarchy menu):
# they skip the transaction when every package is already present, then
# pacman/yay -S --needed --noconfirm. Do not use yay -Sua here — that is
# a sysupgrade and reinstalls/rebuilds up-to-date AUR packages.
# Prompts are DNS (if the drop-in is missing), the Zen→LibreWolf hijack,
# and Seahorse / reboot at the end.

# Helpers live only in the repo. Extract the zip into:
#   $HOME/Documents/_git/dotfiles/.local/share/bin
# Do not use $HOME/.local/share for scripts.

DOTFILES="$HOME/Documents/_git/dotfiles"
DOTFILES_BIN="$HOME/Documents/_git/dotfiles/.local/share/bin"
cd "$DOTFILES" || exit 1

allow_pacman() {
  sudo env OMARCHY_ALLOW_DIRECT_PACMAN=1 pacman "$@"
}

pkg_add() {
  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    omarchy-pkg-add "$@"
    return
  fi
  allow_pacman -S --needed --noconfirm "$@"
}

aur_add() {
  if command -v omarchy-pkg-aur-add >/dev/null 2>&1; then
    omarchy-pkg-aur-add "$@"
    return
  fi
  OMARCHY_ALLOW_DIRECT_PACMAN=1 \
    yay --sudoflags '--preserve-env=OMARCHY_ALLOW_DIRECT_PACMAN' -S --needed --noconfirm "$@"
}

printf '%s\n' "Omarchy 4.0 post-install"
printf '%s\n' "Repo root: $DOTFILES"
printf '%s\n' "Helpers:   $DOTFILES_BIN"
printf '%s\n' "ALPM bypass: OMARCHY_ALLOW_DIRECT_PACMAN=1"
printf '\n'

# --- Packages (pacman) -------------------------------------------------------
# Original (Omarchy 3 / unguarded):
# sudo pacman -S --noconfirm dnsutils keyd freerdp remmina dash ydotool qt6-tools
# sudo pacman -S --noconfirm imv bc samba smbclient
# sudo pacman -S --noconfirm bind wipe
# sudo pacman -S --noconfirm gimp caligula
# sudo pacman -S --noconfirm gamemode
# sudo pacman -S --noconfirm flatpak
# sudo pacman -Syu

# Most essential pacman applications
pkg_add dnsutils keyd freerdp remmina dash ydotool qt6-tools

# Active Directory & other super useful utilities
pkg_add imv bc samba smbclient
pkg_add bind wipe

# sudo cp <path> /etc/systemd/resolved.conf # within git root
# sudo systemctl restart systemd-resolved

# Set up KeyD
# sudo cp etc/keyd.conf /etc/keyd/keyd.conf # within git root
if [ -f "$DOTFILES/etc/keyd.conf" ]; then
  sudo mkdir -p /etc/keyd
  sudo cp "$DOTFILES/etc/keyd.conf" /etc/keyd/keyd.conf
else
  printf '%s\n' "etc/keyd.conf not found in $DOTFILES; skipping KeyD copy."
fi

pkg_add gimp caligula seahorse

# --- Packages (AUR / yay) ----------------------------------------------------
# Original (unguarded):
# yay -Sua --noconfirm --needed brave-bin-origin-nightly-bin ente-auth-bin
# yay -Sua --noconfirm --needed ascii-image-converter beeper-v4-bin freetube-bin librewolf-hellfire-bin
# yay -Sua --needed --noconfirm ddcui

# Brave Origin via Omarchy Quattro (Install > Browser > Brave Origin)
# as a standard user — not sudo, not a raw yay package.
#   omarchy install browser brave-origin
# if command -v omarchy >/dev/null 2>&1; then
  # omarchy install browser brave-origin
# else
#   printf '%s\n' "omarchy not found; skipping Brave Origin."
# fi

# Most essential AUR applications
# aur_add ente-auth-bin
# Less essential AUR applications
aur_add ascii-image-converter beeper-v4-bin freetube-bin librewolf-hellfire-bin
# AUR extras
aur_add ddcui

# # Misc
pkg_add gamemode
pkg_add flatpak
allow_pacman -Syu --needed --noconfirm

# Scripts stay in $DOTFILES_BIN (extract the zip there). Never $HOME/.local/share.
# mkdir -p "$HOME/.local/share/bin"
# mkdir -p "$HOME/.local/bin"
# touch . "$HOME/.local/share/../bin/env"

omarchy pkg aur add ente-auth-bin
# Using newer omarchy package installation
omarchy pkg add libayatana-indicator
# Enable services
sudo systemctl enable --now keyd

# --- $HOME/_git → Documents/_git ---------------------------------------------
# The dotfiles repo lives in Documents/_git/dotfiles. A short symlink at
# $HOME/_git keeps paths like ~/_git/dotfiles stable.
# Relative target is resolved from the link's directory ($HOME).
if [ -L "$HOME/_git" ]; then
  printf '%s\n' "$HOME/_git already exists as a symlink; leaving it."
elif [ -e "$HOME/_git" ]; then
  printf '%s\n' "$HOME/_git exists and is not a symlink; leaving it."
else
  ln -s Documents/_git "$HOME/_git"
  printf '%s\n' "Linked $HOME/_git -> Documents/_git"
fi

# --- Snapper retention -------------------------------------------------------
# Omarchy's root config defaults to NUMBER_LIMIT=5 / NUMBER_LIMIT_IMPORTANT=5
# (pre-update recovery snapshots, timeline off). Keep 9 numbered backups
# and 4 important ones.
if command -v snapper >/dev/null 2>&1 && [ -f /etc/snapper/configs/root ]; then
  sudo snapper -c root set-config NUMBER_LIMIT=9 NUMBER_LIMIT_IMPORTANT=4
  printf '%s\n' "Snapper root: NUMBER_LIMIT=9 NUMBER_LIMIT_IMPORTANT=4"
else
  printf '%s\n' "No snapper root config found; skipping snapshot limit change."
fi

# --- Keyring unlock (encrypted Login keyring + root secret) ------------------
# https://github.com/omacom/omarchy/discussions/3331#discussioncomment-15247393
# Omarchy autologin cannot unlock an encrypted keyring via PAM. Store a
# LUKS-protected secret as root and inject it after the user runtime dir is up.
# Seahorse (installed above) is used once, by hand, to set the Login password.
KEYRING_UID="$(id -u)"
KEYRING_USER="$(id -un)"
KEYRING_SCRIPT_SRC="$DOTFILES_BIN/unlock-keyring-secure.sh"
KEYRING_SCRIPT_DST="/usr/local/sbin/unlock-keyring-secure.sh"
KEYRING_UNIT="/etc/systemd/system/keyring-unlock-root.service"
KEYRING_SECRET="/etc/keyring_secret"

if [ ! -f "$KEYRING_SECRET" ]; then
  sudo sh -c 'umask 077; openssl rand -base64 32 > /etc/keyring_secret' \
    && sudo chmod 600 "$KEYRING_SECRET" \
    && sudo chown root:root "$KEYRING_SECRET" \
    && printf '%s\n' "Created $KEYRING_SECRET (root:root 0600)"
else
  printf '%s\n' "$KEYRING_SECRET already exists; leaving it."
fi

if [ -f "$KEYRING_SCRIPT_SRC" ]; then
  sudo install -D -m 755 "$KEYRING_SCRIPT_SRC" "$KEYRING_SCRIPT_DST"
else
  printf '%s\n' "unlock-keyring-secure.sh missing from repo; writing a copy to $KEYRING_SCRIPT_DST"
  sudo tee "$KEYRING_SCRIPT_DST" > /dev/null <<'KEYRING_EOF'
#!/bin/bash
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

# --- Cleanup phase -----------------------------------------------------------
# remove-dev-envs is obsolete on Omarchy 4.0 (dev env is no longer a
# removable overlay of ~/.local/share/omarchy; that path is a pacman-owned
# symlink). Left commented for history.
printf '%s\n' "Attempting to run extra scripts..."
sleep 2
printf '%s\n' "..."
sleep 1
# omarchy-remove-dev-env-noargs

# sh .local/share/bin/configure-resolve-cfg.sh # within git root
# Conf exists → no prompts. Blank-default prompts only run when the drop-in
# is missing. Test via sudo so a root-only file still counts as present.
# Only the repo copy — never $HOME/.local/share.
DROP_FILE="/etc/systemd/resolved.conf.d/10-ad-domain.conf"
RESOLVE_CFG="$HOME/Documents/_git/dotfiles/.local/share/bin/execute-resolveconf-cfg-implement.sh"
if sudo test -f "$DROP_FILE" || [ -f "$DROP_FILE" ]; then
  printf '%s already exists; skipping resolvconf (no domain/DNS prompts).\n' "$DROP_FILE"
elif [ -f "$RESOLVE_CFG" ]; then
  sh "$RESOLVE_CFG"
else
  printf '%s\n' "resolve-cfg script not found at $RESOLVE_CFG — skip."
fi

# --- Zen launcher → LibreWolf Hellfire ---------------------------------------
# Omarchy's "zen" default-browser slot points at this user launcher instead
# of the real Zen package.
printf '\n'
printf 'Hijack Omarchy Zen launcher so it starts LibreWolf Hellfire? [y/N] '
IFS= read -r ZEN_HIJACK || ZEN_HIJACK=""
case "$ZEN_HIJACK" in
  y|Y|yes|YES)
    LIBREWOLF_BIN="$(command -v librewolf || true)"
    if [ -z "$LIBREWOLF_BIN" ]; then
      printf '%s\n' "librewolf not on PATH; skipping Zen hijack."
    else
      mkdir -p ~/.local/bin ~/.local/share/applications
      ln -sfn "$LIBREWOLF_BIN" ~/.local/bin/zen-browser
      cat > ~/.local/share/applications/zen.desktop <<EOF
[Desktop Entry]
Type=Application
Name=LibreWolf Hellfire
Exec=$LIBREWOLF_BIN %u
Icon=librewolf
Terminal=false
StartupNotify=true
StartupWMClass=librewolf
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF
      if command -v omarchy >/dev/null 2>&1; then
        omarchy default browser zen
      else
        printf '%s\n' "omarchy not found; launcher is in place, default not set."
      fi
      printf '%s\n' "Zen launcher now points at $LIBREWOLF_BIN"
    fi
    ;;
  *)
    printf '%s\n' "Leaving Zen launcher unchanged."
    ;;
esac

# --- omarchy-update tail: orphans + post-update hook -------------------------
# Same finishing steps as omarchy-update-perform, if those commands exist.
if command -v omarchy-update-orphan-pkgs >/dev/null 2>&1; then
  omarchy-update-orphan-pkgs || true
elif command -v pacman >/dev/null 2>&1; then
  orphans=$(pacman -Qtdq 2>/dev/null || true)
  if [ -n "$orphans" ]; then
    printf '%s\n' "Removing orphan / leftover make-dep packages..."
    # shellcheck disable=SC2086
    allow_pacman -Rs --noconfirm $orphans || true
  fi
fi

if command -v omarchy-hook >/dev/null 2>&1; then
  omarchy-hook post-update || true
fi

# --- Manual Seahorse steps (interactive) then reboot prompt ------------------
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

# omarchy-update-restart prompts if the running kernel no longer matches
# an installed vmlinuz (or if ~/.local/state/omarchy/reboot-required exists).
if command -v omarchy-update-restart >/dev/null 2>&1; then
  omarchy-update-restart
else
  printf '%s\n' "omarchy-update-restart not found; reboot yourself if the kernel was updated."
fi
