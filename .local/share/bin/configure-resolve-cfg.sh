#!/bin/sh
set -u

CONF="/etc/systemd/resolved.conf"
BACKUP="${CONF}.bak"
SYSDIR="/etc/systemd/resolved.conf.d"
LOCAL_CONF="./20-search-domain.conf"

# Reset the local template to its default (blank Domains=) on any exit
restore_default() {
  [ -f "$LOCAL_CONF" ] && sed -i 's/^Domains=.*/Domains=/' "$LOCAL_CONF"
printf "Local template reset to default.\n"
}
trap restore_default EXIT

# Create the template if it doesn't exist yet
if [ ! -f "$LOCAL_CONF" ]; then
  printf '[Resolve]\nDNS=10.10.10.254 10.10.10.253\nDomains=\n' > "$LOCAL_CONF"
fi

# Prompt for domain
printf "Enter search domain (e.g. ad.example.com): "
if ! IFS= read -r DOMAIN || [ -z "$DOMAIN" ]; then
  printf "No domain entered. Exiting.\n" >&2
  exit 1
fi

# Basic validation (letters, digits, dot, dash, underscore, space for multiple domains)
case "$DOMAIN" in
  *[!A-Za-z0-9._\ -]*)
    printf "Invalid characters in domain. Exiting.\n" >&2
    exit 1
    ;;
esac

# Insert the domain into the local template
sed -i "s/^Domains=.*/Domains=${DOMAIN}/" "$LOCAL_CONF" || exit 1

# Back up resolved.conf (keep the first backup if one already exists)
if [ -f "$CONF" ] && [ ! -f "$BACKUP" ]; then
  sudo cp -p "$CONF" "$BACKUP" || exit 1
  printf "Backed up %s to %s\n" "$CONF" "$BACKUP"
fi

# Install the drop-in
sudo mkdir -p "$SYSDIR" || exit 1
sudo install -m 644 "$LOCAL_CONF" "$SYSDIR/" || exit 1
printf "Installed %s to %s/\n" "$LOCAL_CONF" "$SYSDIR"
printf "Done. \n"

# Apply the change
printf "Configuration updated, restarting systemd-resolved.service... \n"
sudo systemctl restart systemd-resolved || exit 1
printf "Done. The git-synchronised config was reset locally.\n"

