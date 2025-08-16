#!/bin/bash

# Sai em caso de erro, variáveis não definidas ou falhas em pipelines
set -euo pipefail

# Garante que o script não seja executado como root
if [[ $EUID -eq 0 ]]; then
    echo "Este script não deve ser executado como root. Execute como usuário normal com privilégios sudo."
    exit 1
fi

# Configura o pacman: downloads paralelos e ILoveCandy
echo "Configurando pacman.conf..."
sudo sed -i 's/#ParallelDownloads = .*/ParallelDownloads = 10/' /etc/pacman.conf
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/\[options\]/a ILoveCandy' /etc/pacman.conf
fi

# Atualiza o sistema
echo "Atualizando o sistema..."
sudo pacman -Syu --noconfirm

# Instala dependências para compilar o paru
echo "Instalando base-devel e git para o paru..."
sudo pacman -S --needed base-devel git --noconfirm

# Instala o paru do AUR
echo "Instalando o paru..."
if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/paru
else
    echo "paru já está instalado."
fi

# Instala pacotes do repositório oficial
echo "Instalando pacotes do pacman..."
sudo pacman -S --noconfirm \
    fastfetch \
    kitty \
    fish \
    starship \
    flatpak \
    firefox \
    mpv \
    noto-fonts-cjk \
    tlp

# Instala pacotes do AUR
echo "Instalando pacotes do AUR..."
paru -S --noconfirm \
    ttf-jetbrains-mono \
    google-chrome \
    geary \
    onlyoffice-bin \
    brave-bin \
    anydesk-bin \
    visual-studio-code-bin \
    hypnotix-wayland \
    webapp-manager \
    preload

# Configura o relógio do sistema
echo "Configurando o relógio do sistema..."
gsettings set org.gnome.desktop.interface clock-format '12h'
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Configura o GRUB
echo "Configurando o GRUB..."
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash mem_sleep_default=deep snd_hda_intel.dmic_detect=0 acpi_enforce_resources=lax i915.enable_dc=0"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Adiciona o usuário ao grupo power
echo "Adicionando o usuário ao grupo power..."
sudo usermod -aG power "$USER"

# Configura o kitty como terminal padrão
echo "Configurando o kitty..."
gsettings set org.gnome.desktop.default-applications.terminal exec /usr/bin/kitty
gsettings set org.gnome.desktop.default-applications.terminal exec-arg ""
mkdir -p ~/.config/kitty
cat > ~/.config/kitty/kitty.conf << 'EOF'
font_family JetBrains Mono SemiBold
font_size 11
background_opacity 0.8
cursor_shape beam
linux_display_server x11
EOF

# Configura o fish como shell padrão
echo "Configurando o fish..."
if ! grep -q "/usr/bin/fish" /etc/shells; then
    echo "/usr/bin/fish" | sudo tee -a /etc/shells
fi
if [[ $SHELL != *fish ]]; then
    if chsh -s /usr/bin/fish; then
        echo "Fish definido como shell padrão. Faça logout e login novamente para aplicar."
    else
        echo "Erro: Não foi possível definir fish como shell padrão. Verifique se /usr/bin/fish está em /etc/shells e tente manualmente com 'chsh -s /usr/bin/fish'."
    fi
else
    echo "Fish já é o shell padrão."
fi
mkdir -p ~/.config/fish
cat > ~/.config/fish/config.fish << 'EOF'
set fish_greeting ""
starship init fish | source
EOF

# Configura o tlp
echo "Configurando o tlp..."
sudo systemctl enable tlp.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Configura o preload
echo "Configurando o preload..."
sudo systemctl enable preload
sudo systemctl start preload

# Configura o pwfeedback
echo "Configurando o pwfeedback..."
if ! grep -q "Defaults.*pwfeedback" /etc/sudoers; then
    echo "Defaults env_reset,pwfeedback" | sudo tee -a /etc/sudoers.d/pwfeedback > /dev/null
    if sudo visudo -c -f /etc/sudoers.d/pwfeedback; then
        echo "pwfeedback configurado com sucesso."
    else
        echo "Erro: Falha ao configurar pwfeedback. Verifique a sintaxe do arquivo /etc/sudoers.d/pwfeedback manualmente."
        sudo rm -f /etc/sudoers.d/pwfeedback
    fi
else
    echo "pwfeedback já está configurado."
fi

echo "Configuração pós-instalação concluída! Reinicie o sistema para garantir que todas as mudanças sejam aplicadas."
