#!/bin/sh
sh .local/share/bin/configure-resolve-cfg.sh

printf "Restarting systemd-resolved\n"
printf ".\n"
sudo systemctl restart systemd-resolved
printf ".\n"
printf "Done."
