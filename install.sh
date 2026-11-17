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

sudo apt update -y && \
sudo apt install -y -t trixie-backports \
  linux-image-amd64 \
  linux-headers-amd64 \
  $(paste -sd' ' packages)

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

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

[org/gnome/desktop/app-folders]
folder-children=['System', 'Utilities', 'YaST', 'Pardus']

[org/gnome/desktop/app-folders/folders/System]
apps=['nm-connection-editor.desktop','debian-xterm.desktop', 'debian-uxterm.desktop']
name='X-GNOME-Shell-System.directory'
translate=true

[org/gnome/shell]
app-picker-layout=[{'firefox.desktop': <{'position': <0>}>, 'thunderbird.desktop': <{'position': <1>}>, 'com.visualstudio.CodeOSS.desktop': <{'position': <2>}>, 'libreoffice-writer.desktop': <{'position': <3>}>, 'libreoffice-calc.desktop': <{'position': <4>}>, 'org.gnome.Console.desktop': <{'position': <5>}>, 'spotify.desktop': <{'position': <6>}>, 'org.keepassxc.KeePassXC.desktop': <{'position': <7>}>, 'com.obsproject.Studio.desktop': <{'position': <8>}>, 'steam.desktop': <{'position': <9>}>, 'org.gnome.FileRoller.desktop': <{'position': <10>}>, 'org.qbittorrent.qBittorrent.desktop': <{'position': <11>}>, 'org.remmina.Remmina.desktop': <{'position': <12>}>, 'vlc.desktop': <{'position': <13>}>, 'com.mattjakeman.ExtensionManager.desktop': <{'position': <14>}>, 'org.gnome.Settings.desktop': <{'position': <15>}>}, {'System': <{'position': <0>}>, 'libreoffice-startcenter.desktop': <{'position': <1>}>}]

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Shift><Control>s'
command='flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE'
name='Gradia Screenshot'

[org/gnome/Console]
audible-bell=false
font-scale=1.2
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
