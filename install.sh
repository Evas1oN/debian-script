#!/bin/bash
[[ $EUID -eq 0 ]] && { echo "Please do not use root user"; exit 1; }

set -euo pipefail

sudo dpkg --add-architecture i386

sudo tee /etc/apt/apt.conf.d/90recommends > /dev/null <<'EOL'
APT::Install-Recommends "false";
EOL

sudo rm -f /etc/apt/sources.list >> /dev/null || true

sudo cp sources.list.d/{debian.sources,debian-backports.sources} /etc/apt/sources.list.d/

sudo apt update -y && sudo apt install -y curl ca-certificates

sudo curl -fsSL https://repo.steampowered.com/steam/archive/stable/steam.gpg -o /usr/share/keyrings/steam.gpg

sudo cp sources.list.d/* /etc/apt/sources.list.d/

sudo tee /etc/apt/preferences.d/mozilla > /dev/null <<'EOL'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOL

sudo apt update -y

sudo apt install -y -t trixie-backports linux-image-amd64 linux-headers-amd64

sudo apt upgrade -y -t trixie-backports

sudo apt install -y -t trixie-backports --no-install-recommends $(paste -sd' ' packages)

dconf load / <<'EOL'
[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('xkb', 'ru')]
xkb-options=['grp:alt_shift_toggle']

[org/gnome/desktop/interface]
color-scheme='prefer-dark'

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'

[org/gnome/shell]
enabled-extensions=['blur-my-shell@aunetx', 'drive-menu@gnome-shell-extensions.gcampax.github.com', 'ubuntu-appindicators@ubuntu.com']

[org/gnome/nautilus/preferences]
always-use-location-entry=true
EOL

sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null <<'EOL'
[main]
dns=dnsmasq
EOL

if [ -f /etc/network/interfaces ]; then
  sudo mv /etc/network/interfaces /etc/network/interfaces.bak
  sudo systemctl restart NetworkManager
  sudo nmcli general reload
fi

sudo systemctl disable dnsmasq
sudo systemctl enable gdm3