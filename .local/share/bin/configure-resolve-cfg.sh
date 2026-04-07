#!/bin/sh
# Dash-compatible script to prompt domain and set `Domains=ad.my.domain.tld in systemd-resolved
# Creates a backup at ~/resolveconf.bak if not present.

CONF="/etc/systemd/resolved.conf"
BACKUP="${CONF}.bak"

# Prompt for domain
printf "Enter Active Directory Domain (e.g. ad.example.com): "
if ! IFS= read -r DOMAIN || [ -z "$DOMAIN" ]; then
  printf "No domain entered. Exiting.\n" >&2
  exit 1
fi

# Ensure file exists
if [ ! -f "$CONF" ]; then
  printf "Config file %s not found.\n" "$CONF" >&2
  exit 1
fi

# Create backup if not already present
if [ ! -f "$BACKUP" ]; then
  sudo cp "$CONF" "$BACKUP" || { printf "Failed to create backup.\n" >&2; exit 1; }
fi

# Use awk to replace a line that begins (possibly after spaces) with "#Domains=" within [Resolve] section
awk -v dom="$DOMAIN" '
  BEGIN{ replaced=0; in_resolve=0 }
  # Track entering/leaving sections
  /^\s*\[/{ in_resolve = ($0 ~ /^\s*\[Resolve\]/) }
  # Replace a line starting with optional spaces then # (optional space) Domains=
  /^\s*#\s*Domains=/{ if(in_resolve){ sub(/^\s*#\s*Domains=.*/,"Domains=" dom); replaced=1 } }
  { print }
  END{
    if(!replaced) exit 2
  }
' "$CONF" | sudo tee "${CONF}.tmp" > /dev/null
# ' "$CONF" > "${CONF}.tmp"
RC=$?

if [ "$RC" -eq 0 ]; then
  sudo mv "${CONF}.tmp" "$CONF" || { printf "Failed to update config.\n" >&2; rm -f "${CONF}.tmp"; exit 1; }
  printf "Updated %s\n" "$CONF"
  exit 0
fi

# If awk indicated no #Domains= line in [Resolve], insert it.
if [ "$RC" -eq 2 ]; then
  if grep -q '^\s*\[Resolve\]' "$CONF"; then
    awk -v dom="$DOMAIN" '
      BEGIN{ added=0 }
      /^\s*\[Resolve\]/{ print; print "Domains=" dom; added=1; next }
      { print }
' "$CONF" | sudo tee "${CONF}.tmp" > /dev/null && sudo mv "${CONF}.tmp" "$CONF" && printf "Inserted Domains= under [Resolve] in %s\n" "$CONF" && exit 0

    printf "Failed to insert Domains= line.\n" >&2
    sudo rm -f "${CONF}.tmp"
    exit 1
  else
    # Append new [Resolve] section
    {
      printf "\n[Resolve]\n"
      printf "Domains=%s\n" "$DOMAIN"
} | sudo tee -a "$CONF" > /dev/null || { printf "Failed to append [Resolve] section.\n" >&2; exit 1; }
    printf "Appended [Resolve] with Domains= to %s\n" "$CONF"
    exit 0
  fi
fi

# Any other error
printf "Unexpected error (rc=%s).\n" "$RC" >&2
rm -f "${CONF}.tmp"
exit 1
