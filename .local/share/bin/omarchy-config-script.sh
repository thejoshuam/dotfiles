#/bin/bash
# Most essential pacman applications
sudo pacman -S --noconfirm dnsutils keyd freerdp remmina dash ydotool qt6-tools

# Active Directory & other super useful utilities
sudo pacman -S --noconfirm imv bc samba smbclient
sudo pacman -S --noconfirm bind wipe

# sudo cp <path> /etc/systemd/resolved.conf # within git root
# sudo systemctl restart systemd-resolved

# Set up KeyD
sudo cp etc/keyd.conf /etc/keyd/keyd.conf # within git root

sudo pacman -S --noconfirm gimp caligula


# Most essential AUR applications
yay -Sua --noconfirm --needed brave-bin-origin-nightly-bin ente-auth-bin
# Less essential AUR applications
yay -Sua --noconfirm --needed ascii-image-converter beeper-v4-bin freetube-bin librewolf-hellfire-bin
# AUR extras
yay -Sua --needed --noconfirm ddcui

# # Misc
sudo pacman -S --noconfirm gamemode
sudo pacman -S --noconfirm flatpak
sudo pacman -Syu

mkdir -p $HOME/.local/share/bin
mkdir -p $HOME/.local/bin
touch . "$HOME/.local/share/../bin/env"

# Enable services
sudo systemctl enable --now keyd

# # Cleanup phase
printf '%s\n' "Attempting to run extra scripts..."
sleep 2
printf '%s\n' "..."
sleep 1
omarchy-remove-dev-env-noargs

sh .local/share/bin/configure-resolve-cfg.sh # within git root
