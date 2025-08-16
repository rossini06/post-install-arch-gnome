sudo pacman -S git --noconfirm
cd Downloads/
git clone https://github.com/rossini06/post-install-arch-gnome.git
cd post-install-arch-gnome/

chmod +x post-install-gnome-arch-v1.0.sh
./post-install-gnome-arch-v1.0.sh

pacman -S adw-gtk-theme --noconfirm

flatpak install flathub com.mattjakeman.ExtensionManager -y
