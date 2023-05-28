#!/bin/bash

while true
do
  clear
  echo -e "Welcome to AltServer Linux Installer!\n"
  echo -e "Created by: syhmi\n"
  echo -e "1. Install dependencies"
  echo -e "2. Pair iPhone with AltServer"
  echo -e "3. Exit Script\n"

  read -p "Choose your option: " optsel

  cd ~

  if [ $optsel -eq 1 ]; then
    mkdir altserver
    cd ~/altserver

    sudo apt update
    sudo apt upgrade

    echo "Installing dependencies..."
    sudo apt install -y libavahi-compat-libdnssd-dev usbmuxd ninja-build ldc libplist-dev libimobiledevice-dev libgtk-3-0 dub openssl curl wget
    echo "Done!"

    echo "Installing libimobiledevice-glue..."
    sudo apt install -y build-essential pkg-config checkinstall git autoconf automake libtool-bin libplist-dev
    git clone https://github.com/libimobiledevice/libimobiledevice-glue.git
    cd libimobiledevice-glue
    ./autogen.sh
    make
    sudo make install
    cd ..
    rm -rf libimobiledevice-glue
    echo "Done!"

    echo "Installing libimobiledevice..."
    sudo apt install -y libusbmuxd-dev libimobiledevice-glue-dev libssl-dev
    git clone https://github.com/libimobiledevice/libimobiledevice.git
    cd libimobiledevice
    ./autogen.sh
    make
    sudo make install
    cd ..
    rm -rf libimobiledevice
    echo "Done!"

    echo "Installing rustup and setting up toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    rustup toolchain install stable
    rustup default stable
    echo "Done!"

    echo "Setting up usbmuxd..."
    echo >> /lib/systemd/system/usbmuxd.service
    echo "[Install]" >> /lib/systemd/system/usbmuxd.service
    echo "WantedBy=multi-user.target" >> /lib/systemd/system/usbmuxd.service
    echo "Enabling services..."
    sudo systemctl enable --now avahi-daemon.service
    sudo systemctl enable --now usbmuxd
    sudo apt-get install avahi-utils
    echo "Done!"

    echo "Downloading AltServer Linux..."
    wget https://github.com/NyaMisty/AltServer-Linux/releases/download/v0.0.5/AltServer-aarch64 -O altserver
    chmod +x altserver
    sudo mv altserver /usr/bin/altserver
    echo "Done!"
    echo "Downloading netmuxd..."
    wget https://github.com/jkcoxson/netmuxd/releases/download/v0.1.4/aarch64-linux-netmuxd -O netmuxd
    chmod +x netmuxd
    sudo mv netmuxd /usr/bin/netmuxd

    echo "Installing Docker..."
    curl -sSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    docker run -d -v lib_cache:/opt/lib/ --restart=always -p 6969:6969 --name anisette dadoum/anisette-server:latest

    echo "Creating directory and files..."
    touch run-altserver.sh
    touch run-netmuxd.sh
    touch restart-altserver.sh
    echo "Files created!"

    echo "Setting up files..."
    chmod +x run-altserver.sh
    chmod +x run-netmuxd.sh
    chmod +x restart-altserver.sh
    echo -e "#!/bin/bash\n\nsudo ALTSERVER_ANISETTE_SERVER=http://127.0.0.1:6969 altserver" >> altserver/run-altserver.sh
    echo -e "#!/bin/bash\n\nnetmuxd --disable-unix --host 127.0.0.1" >> altserver/run-netmuxd.sh
    echo -e "#!/bin/bash\n\nsudo systemctl restart usbmuxd\nsleep 10\nsudo systemctl restart netmuxd\nsleep 10\nsudo systemctl restart altserver" >> altserver/restart-altserver.sh
    echo "Done setting up files!"

    # write out current crontab
    crontab -l > mycron
    # echo new cron into cron file
    echo "@reboot sleep 20 && netmuxd > ~/altserver/log/netmuxd.log 2>&1" >> mycron
    echo "@reboot sleep 20 && ALTSERVER_ANISETTE_SERVER=http://127.0.0.1:6969 altserver > ~/altserver/log/altserver.log 2>&1" >> mycron
    # install new cron file
    crontab mycron
    rm mycron

    echo -e "You need to reboot to use AltServer\n"
    read -p "Do you want to reboot now? (y/N): " optreboot
    if [ $optreboot == "y" ] || [ $optreboot == "Y" ]; then
      sudo reboot
    fi

  elif [ $optsel -eq 2 ]; then
    clear
    echo -e "Plug in your iPhone and select \"Trust\" if prompted.\n"
    read -p "Press enter to continue"

    echo "Please wait..."
    sleep 10
    
    idevicepair validate
    echo -e "You can unplug your device if you see yours.\n\n"
    read -p "Press enter to continue"
  elif [ $optsel -eq 3 ]; then
    echo "Bye!"
    exit 0
  else
    echo "Wrong option!"
  fi
done

exit 0
