#/bin/bash
# Most essential pacman applications
sudo pacman -S --noconfirm dnsutils keyd freerdp remmina imv dash

# Active Directory
sudo pacman -S --noconfirm samba smbclient
sudo pacman -S --noconfirm bind

# sudo cp <path> /etc/systemd/resolved.conf # within git root
# sudo systemctl restart systemd-resolved

# Set up KeyD
sudo cp etc/keyd.conf /etc/keyd/keyd.conf # within git root

sudo pacman -S --noconfirm gimp caligula


# Most essential AUR applications
yay -Sua brave-bin ente-auth-bin
# Less essential AUR applications
yay -Sua ascii-image-converter beeper-v4-bin freetube-bin librewolf-bin


# # Misc
sudo pacman -S --noconfirm gamemode
sudo pacman -S --noconfirm flatpak
sudo pacman -Syu

# # Cleanup phase
sudo pacman -Rnu chromium

sh .local/share/bin/configure-resolve-conf.sh # within git root
