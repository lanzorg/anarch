#!/usr/bin/env bash

setup_system()
{
    # Change the default DNS servers.
    if ! grep -Fxq 'nameserver 1.1.1.1' /etc/resolv.conf; then
        cat /dev/null | sudo tee /etc/resolv.conf
        echo 'nameserver 1.1.1.1' | sudo tee -a /etc/resolv.conf
        echo 'nameserver 1.0.0.1' | sudo tee -a /etc/resolv.conf
        sudo chattr +i /etc/resolv.conf
    fi

    # Fix the wrong clock time.
    sudo pacman -S --noconfirm ntp
    sudo ntpd -qg && sudo hwclock --systohc

    # Make packages compilation and compression faster.
    sudo sed -i "s/#MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/g" /etc/makepkg.conf
    sudo sed -i "s/COMPRESSXZ=.*/COMPRESSXZ=(xz -c -z - --threads=0)/g" /etc/makepkg.conf
    sudo sed -i "s/COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q - --threads=0)/g" /etc/makepkg.conf

    # Reduce the grub timeout.
    sudo sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/g" /etc/default/grub
    sudo sed -i "s/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/g" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    # Install the intel drivers.
    sudo pacman -S --noconfirm libva-intel-driver libva-utils libvdpau-va-gl lib32-vulkan-intel vulkan-intel

    # Install the intel microcode package
    sudo pacman -S --noconfirm intel-ucode
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    # Install the freetype2-cleartype package.
    yay -S --noconfirm --useask freetype2-cleartype

    # Fix horribly rendered as bitmap fonts.
    sudo ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
    sudo ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
    sudo ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
    fc-cache -f

    # Change the fontconfig settings.
    settings="${HOME}/.config/fontconfig/conf.d/20-no-embedded.conf"
    mkdir -p $(dirname ${settings}) && cat /dev/null | tee "${settings}"
    echo '<?xml version="1.0"?>' | tee -a "${settings}"
    echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' | tee -a "${settings}"
    echo '<fontconfig>' | tee -a "${settings}"
    echo '  <match target="font">' | tee -a "${settings}"
    echo '    <edit name="embeddedbitmap" mode="assign">' | tee -a "${settings}"
    echo '      <bool>false</bool>' | tee -a "${settings}"
    echo '    </edit>' | tee -a "${settings}"
    echo '  </match>' | tee -a "${settings}"
    echo '</fontconfig>' | tee -a "${settings}"

    # Install some missing fonts.
    sudo pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-extra
}

setup_gnome()
{
    # Enable the xorg backend by default.
    sudo sed -i "s/#WaylandEnable=false/WaylandEnable=false/g" /etc/gdm/custom.conf

    # Change the gnome fonts.
    sudo pacman -S --noconfirm ttf-ubuntu-font-family
    gsettings set org.gnome.desktop.interface font-name 'Ubuntu 10'
    gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 12'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 10'
    gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

    # Install the papirus-icon-theme package.
    sudo pacman -S --noconfirm papirus-icon-theme
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'

    # Install the arc-gtk-theme package.
    sudo pacman -S --noconfirm arc-gtk-theme
    gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'

    # Enable animations.
    gsettings set org.gnome.desktop.interface enable-animations true

    # Enable maximize and minimize window buttons.
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    # Center new windows.
    gsettings set org.gnome.mutter center-new-windows true

    # Disable the auto suspend when idle.
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

    # Disable the hot-corners.
    gsettings set org.gnome.desktop.interface enable-hot-corners false

    # Enable and configure night light.
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
    
    # Install and configure dash-to-panel.
    yay -S --noconfirm gnome-shell-extension-dash-to-panel
    gsettings set org.gnome.shell disable-user-extensions false
    gsettings set org.gnome.shell enabled-extensions "['dash-to-panel@jderose9.github.com']"
    # dconf write /org/gnome/shell/extensions/dash-to-panel/animate-show-apps false
    dconf write /org/gnome/shell/extensions/dash-to-panel/appicon-margin 2
    dconf write /org/gnome/shell/extensions/dash-to-panel/appicon-padding 6
    dconf write /org/gnome/shell/extensions/dash-to-panel/panel-size 36
    dconf write /org/gnome/shell/extensions/dash-to-panel/show-show-apps-button true
    dconf write /org/gnome/shell/extensions/dash-to-panel/show-showdesktop-button false
    dconf write /org/gnome/shell/extensions/dash-to-panel/show-tooltip false
    # dconf write /org/gnome/shell/extensions/dash-to-panel/show-window-previews false
    dconf write /org/gnome/shell/extensions/dash-to-panel/trans-panel-opacity 0.7
    dconf write /org/gnome/shell/extensions/dash-to-panel/trans-use-custom-opacity true

    # Pin my favorite applications.
    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'jdownloader.desktop', 'transmission-gtk.desktop', 'insomnia.desktop', 'vmware-workstation.desktop', 'org.gnome.Terminal.desktop', 'jetbrains-webstorm.desktop', 'visual-studio-code.desktop', 'org.gnome.Lollypop.desktop', 'mpv.desktop']"

    # Install the p7zip and unrar packages.
    sudo pacman -S --noconfirm p7zip unrar

    # Set fileroller as default program to handle archive files.
    xdg-mime default 'org.gnome.FileRoller.desktop' application/x-7z-compressed application/x-7z-compressed-tar \
        application/x-ace application/x-alz application/x-ar application/x-arj application/x-bzip \
        application/x-bzip-compressed-tar application/x-bzip1 application/x-bzip1-compressed-tar application/x-cabinet \
        application/x-cd-image application/x-compress application/x-compressed-tar application/x-cpio application/x-deb \
        application/x-ear application/x-ms-dos-executable application/x-gtar application/x-gzip \
        application/x-gzpostscript application/x-java-archive application/x-lha application/x-lhz application/x-lrzip \
        application/x-lrzip-compressed-tar application/x-lz4 application/x-lzip application/x-lzip-compressed-tar \
        application/x-lzma application/x-lzma-compressed-tar application/x-lzop application/x-lz4-compressed-tar \
        application/x-lzop-compressed-tar application/x-ms-wim application/x-rar application/x-rar-compressed \
        application/x-rpm application/x-source-rpm application/x-rzip application/x-rzip-compressed-tar \
        application/x-tar application/x-tarz application/x-stuffit application/x-war application/x-xz \
        application/x-xz-compressed-tar application/x-zip application/x-zip-compressed application/x-zoo application/zip \
        application/x-archive application/vnd.ms-cab-compressed application/vnd.debian.binary-package application/gzip
}

setup_android()
{
    # Install android command line tools.
    yay -S --needed --noconfirm android-sdk-cmdline-tools-latest
    sudo groupadd android-sdk
    sudo gpasswd -a "${USER}" android-sdk
    sudo setfacl -R -m g:android-sdk:rwx /opt/android-sdk
    sudo setfacl -d -m g:android-sdk:rwX /opt/android-sdk
    sudo chmod -R a+w /opt/android-sdk
    source /etc/profile

    # Add the environment variables to .bashrc file.
    if ! grep -Fxq 'export ANDROID_HOME="/opt/android-sdk"' "${HOME}/.bashrc"; then
        echo '' | tee -a "$HOME/.bashrc"
        echo '# Android environment variables' | tee -a "$HOME/.bashrc"
        echo 'export ANDROID_HOME="/opt/android-sdk"' | tee -a "${HOME}/.bashrc"
        echo 'export PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools"' | tee -a "${HOME}/.bashrc"
    fi

    # Install android build tools, platforms and system images.
    source "${HOME}/.bashrc"
    (for run in {1..1000}; do echo y; done) >> yep.txt
    cat ./yep.txt | sdkmanager --update
    cat ./yep.txt | sdkmanager 'platforms;android-29'
    cat ./yep.txt | sdkmanager 'build-tools;29.0.3'
    cat ./yep.txt | sdkmanager 'system-images;android-29;default;x86'
    cat ./yep.txt | sdkmanager --licenses
    rm ./yep.txt

    # Create an android virtual device.
    avdmanager create avd -k 'system-images;android-29;default;x86' -n 'pixel-xl' -d 'pixel_xl' -f
}

setup_docker()
{
    # Install the docker and docker-compose packages.
    sudo pacman -S --noconfirm docker docker-compose

    # Use it as a non-root user.
    sudo usermod -aG docker "${USER}"
}

setup_firefox()
{
    # Install the firefox package.
    sudo pacman -S --noconfirm firefox
}

setup_flutter()
{
    # Install the flutter package.
    yay -S --noconfirm flutter
    sudo groupadd flutterusers
    sudo gpasswd -a "${USER}" flutterusers
    sudo chown -R "${USER}" /opt/flutter
    sudo chmod -R a+w /opt/flutter

    # Upgrade flutter and accept all the licenses.
    source "${HOME}/.bashrc"
    flutter upgrade && flutter precache
    (for run in {1..1000}; do echo y; done) >> yep.txt
    cat ./yep.txt | flutter doctor --android-licenses
    rm ./yep.txt

    # Disable reporting.
    flutter config --no-analytics
}

setup_git()
{
    # Install the git package.
    sudo pacman -S --noconfirm git

    # Edit the settings.
    git config --global credential.helper 'cache --timeout=21000'
    git config --global user.email 'anonymous@example.com'
    git config --global user.name 'anonymous'
}

setup_insomnia()
{
    # Install the insomnia package.
    yay -S --noconfirm insomnia

    # Edit the settings.
    settings=$(find "${HOME}" -type f -name insomnia.Settings.db)
    if [[ -n "${settings}" ]]; then
        sed -i "s/\"autoHideMenuBar\":false/\"autoHideMenuBar\":true/g" "${settings}"
    fi
}

setup_jdownloader()
{
    # Install the jdk-jetbrains package.
    yay -S --noconfirm jdk-jetbrains
    sudo archlinux-java set jdk-jetbrains

    # Edit the /etc/environment file.
    if ! grep -Fxq '_JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=lcd"' /etc/environment; then
        echo '_JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=lcd"' | sudo tee -a /etc/environment
        source /etc/environment
    fi

    # Install the jdownloader2 package.
    yay -S --noconfirm jdownloader2

    # Edit the settings.
    settings="${HOME}/.jd/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
    jdownloader > /dev/null 2>&1 &
    sleep 5 && while [ ! -f "${settings}" ]; do sleep 2; done
    pkill -f 'java -jar' && sleep 5
    jdownloader > /dev/null 2>&1 &
    sleep 5 && pkill -f 'java -jar' && sleep 5
    sed -i "s/\"bannerenabled\".*/\"bannerenabled\" : false,/g" "${settings}"
    sed -i "s/\"donatebuttonstate\".*/\"donatebuttonstate\" : \"USER_HIDDEN\",/g" "${settings}"
    sed -i "s/\"myjdownloaderviewvisible\".*/\"myjdownloaderviewvisible\" : false,/g" "${settings}"
    sed -i "s/\"speedmetervisible\".*/\"speedmetervisible\" : false,/g" "${settings}"
}

setup_lollypop()
{
    # Install the lollypop package.
    sudo pacman -S --noconfirm lollypop
}

setup_mpv()
{
    # Install the mpv package.
    sudo pacman -S --noconfirm mpv

    # Fix the desktop file.
    sudo sed -i "s/Name=.*/Name=Mpv/g" /usr/share/applications/mpv.desktop

    # Edit the settings.
    settings="${HOME}/.config/mpv/mpv.conf"
    mkdir -p "$(dirname "${settings}")" && cat /dev/null > "${settings}"
    echo 'profile=gpu-hq' | tee -a "${settings}"
    echo 'hwdec=auto' | tee -a "${settings}"
    echo 'interpolation=yes' | tee -a "${settings}"
    echo 'keep-open=yes' | tee -a "${settings}"
    echo 'tscale=oversample' | tee -a "${settings}"
    echo 'video-sync=display-resample' | tee -a "${settings}"
    echo 'ytdl-format="bestvideo[height<=?1080][vcodec!=vp9]+bestaudio/best"' | tee -a "${settings}"
}

setup_nodejs()
{
    # Install the nodejs, npm and yarn packages.
    sudo pacman -S --noconfirm nodejs npm yarn
}

setup_phpstorm()
{
    # Install the phpstorm package.
    yay -S --noconfirm phpstorm
}

setup_python()
{
    # Install the python and python-pipenv packages.
    sudo pacman -S --noconfirm python python-pipenv
}

setup_transmission()
{
    # Install the transmission-gtk package.
    sudo pacman -S --noconfirm transmission-gtk

    # Edit the settings.
    timeout 5s transmission-gtk
    settings="${HOME}/.config/transmission/settings.json"
    sed -i 's/"ratio-limit":.*/"ratio-limit": 0,/g' "${settings}"
    sed -i 's/"ratio-limit-enabled":.*/"ratio-limit-enabled": true,/g' "${settings}"
}

setup_vmware_workstation()
{
    # Install the base-devel and git packages.
    sudo pacman -S --noconfirm base-devel git

    # Install the trizen package.
    git clone https://aur.archlinux.org/trizen.git
    cd trizen && makepkg -si --noconfirm && cd ..
    rm -rf trizen

    # Install the vmware-workstation package.
    directory=$(mktemp -d) && cd "${directory}"
    trizen -G vmware-workstation
    sed -i "s/#_enable_macOS_guests=y/_enable_macOS_guests=y/g" "${directory}/vmware-workstation/PKGBUILD"
    trizen -S -l --noconfirm vmware-workstation
    cd "${HOME}"

    # Enable vmware-workstation services.
    sudo systemctl enable --now vmware-networks.service
    sudo systemctl enable --now vmware-usbarbitrator.service
    sudo systemctl enable --now vmware-hostd.service

    # Enter the license key.
    sudo /usr/lib/vmware/bin/vmware-vmx-debug --new-sn YZ718-4REEQ-08DHQ-JNYQC-ZQRD0

    # Hide the directory by default.
    if ! grep -Fxq 'vmware' "${HOME}/.hidden"; then
        echo 'vmware' | tee -a "${HOME}/.hidden"
    fi
}

setup_visual_studio_code()
{
    # Install the visual-studio-code package.
    yay -S --noconfirm visual-studio-code-bin

    # Install some extensions.
    code --install-extension github.github-vscode-theme
    code --install-extension humao.rest-client

    # Install the ttf-jetbrains-mono package.
    sudo pacman -S --noconfirm ttf-jetbrains-mono

    # Edit the settings.
    settings="${HOME}/.config/Code/User/settings.json"
    mkdir -p $(dirname "${settings}") && cat /dev/null | tee "${settings}"
    echo '{' | tee -a "${settings}"
    echo '    "editor.fontFamily": "JetBrains Mono, monospace",' | tee -a "${settings}"
    echo '    "editor.fontSize": 13,' | tee -a "${settings}"
    echo '    "editor.lineHeight": 30,' | tee -a "${settings}"
    echo '    "window.menuBarVisibility": "toggle",' | tee -a "${settings}"
    echo '    "telemetry.enableTelemetry": false,' | tee -a "${settings}"
    echo '    "telemetry.enableCrashReporter": false,' | tee -a "${settings}"
    echo '    "workbench.colorTheme": "GitHub Dark"' | tee -a "${settings}"
    echo '}' | tee -a "${settings}"
}

setup_webstorm()
{
    # Install the webstorm package.
    yay -S --noconfirm webstorm
}

setup_yay()
{
    # Install the base-devel and git packages.
    sudo pacman -S --noconfirm base-devel git

    # Install the yay-bin package.
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin && makepkg -si --noconfirm && cd ..
    rm -rf yay-bin
}

setup_youtube_dl()
{
    # Install the youtube-dl package.
    sudo pacman -S --noconfirm youtube-dl
}

main()
{
    echo 'Installing and configuring the system...'
    setup_system > /dev/null 2>&1

    echo 'Installing and configuring git...'
    setup_git > /dev/null 2>&1

    echo 'Installing and configuring yay...'
    setup_yay > /dev/null 2>&1

    ###

    echo 'Installing and configuring android...'
    setup_android > /dev/null 2>&1

    echo 'Installing and configuring docker...'
    setup_docker > /dev/null 2>&1

    echo 'Installing and configuring flutter...'
    setup_flutter > /dev/null 2>&1

    echo 'Installing and configuring insomnia...'
    setup_insomnia > /dev/null 2>&1

    echo 'Installing and configuring nodejs...'
    setup_nodejs > /dev/null 2>&1

    echo 'Installing and configuring phpstorm...'
    setup_phpstorm > /dev/null 2>&1

    echo 'Installing and configuring setup_python...'
    setup_setup_python > /dev/null 2>&1

    echo 'Installing and configuring vmware-workstation...'
    setup_vmware_workstation > /dev/null 2>&1

    echo 'Installing and configuring visual-studio-code...'
    setup_visual_studio_code > /dev/null 2>&1

    echo 'Installing and configuring webstorm...'
    setup_webstorm > /dev/null 2>&1

    ###

    echo 'Installing and configuring firefox...'
    setup_firefox > /dev/null 2>&1

    echo 'Installing and configuring jdownloader...'
    setup_jdownloader > /dev/null 2>&1

    echo 'Installing and configuring transmission...'
    setup_transmission > /dev/null 2>&1

    ###

    echo 'Installing and configuring lollypop...'
    setup_lollypop > /dev/null 2>&1

    echo 'Installing and configuring mpv...'
    setup_mpv > /dev/null 2>&1

    echo 'Installing and configuring youtube-dl...'
    setup_youtube_dl > /dev/null 2>&1

    ###

    echo 'Installing and configuring gnome...'
    setup_gnome > /dev/null 2>&1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
