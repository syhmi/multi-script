#!/bin/bash

while true
do
  clear
  echo -e "Welcome to AltServer Linux Installer!\n"
  echo -e "Created by: syhmi\n"
  echo -e "1. Full Installation (First Time Use)"
  echo -e "2. Restart AltServer and netmuxd"
  echo -e "3. Update AltServer and netmuxd"
  echo -e "4. Remove AltServer and netmuxd"
  echo -e "5. Exit Script\n"

  read -p "Choose your option: " optsel

  cd ~

  if [ $optsel -eq 1 ]; then
    echo "Installing dependencies..."
    sudo apt install libavahi-compat-libdnssd-dev usbmuxd -y
    echo "Done!"

    echo "Restarting usbmuxd..."
    sudo systemctl restart usbmuxd
    sleep 5

    clear
    echo -e "Plug in your iPhone and select \"Trust\" if prompted.\n"
    read -p "Press enter to continue"

    echo "Please wait..."
    sleep 10
    
    echo -e "You can unplug your device.\n\n"
    read -p "Press enter to continue"
    
    clear
    
    echo "Downloading AltServer Linux and netmuxd..."
    wget https://github.com/NyaMisty/AltServer-Linux/releases/download/v0.0.5/AltServer-armv7 -O altserver
    wget https://github.com/jkcoxson/netmuxd/releases/download/v0.1.4/armv7-linux-netmuxd -O netmuxd
    clear
    echo "Downloaded altserver and netmuxd!"

    echo "Changing files permissions..."
    chmod +x altserver
    chmod +x netmuxd
    echo "Changed!"
    
    echo "Moving to /usr/bin..."
    sudo mv altserver /usr/bin/altserver
    sudo mv netmuxd /usr/bin/netmuxd
    echo "Moved AltServer and netmuxd!"

    echo "Creating directory and files..."
    mkdir altserver
    touch altserver/run-altserver.sh
    touch altserver/run-netmuxd.sh
    touch altserver/restart-altserver.sh
    echo "Files created!"

    echo "Setting up files..."
    chmod +x altserver/run-altserver.sh
    chmod +x altserver/run-netmuxd.sh
    chmod +x altserver/restart-altserver.sh
    echo -e "#!/bin/bash\n\nexport USBMUXD_SOCKET_ADDRESS=127.0.0.1:27015\naltserver" >> altserver/run-altserver.sh
    echo -e "#!/bin/bash\n\nnetmuxd --disable-unix --host 127.0.0.1" >> altserver/run-netmuxd.sh
    echo -e "#!/bin/bash\n\nsudo systemctl restart usbmuxd\nsleep 10\nsudo systemctl restart netmuxd\nsleep 10\nsudo systemctl restart altserver" >> altserver/restart-altserver.sh
    echo "Done setting up files!"


    echo "Creating system daemon services..."

    # NETMUXD DAEMON
    echo "Creating netmuxd daemon..."
    sudo touch /etc/systemd/system/netmuxd.service
    echo "" | sudo tee -a /etc/systemd/system/netmuxd.service > /dev/null

    echo "[Unit]
Description=netmuxd for altserver
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/altserver/run-netmuxd.sh
Restart=on-failure

[Install]
WantedBy=default.target
" | sudo tee -a /etc/systemd/system/netmuxd.service > /dev/null

    # ALTSERVER DAEMON
    echo "Creating altserver daemon..."

    sudo touch /etc/systemd/system/altserver.service
    echo "" | sudo tee -a /etc/systemd/system/altserver.service > /dev/null

    echo "[Unit]
Description=altserver
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/altserver/run-altserver.sh
Restart=on-failure

[Install]
WantedBy=default.target
" | sudo tee -a /etc/systemd/system/altserver.service > /dev/null


    # RESTART DAEMON
    echo "Creating restart altserver on reboot daemon..."
    sudo touch /etc/systemd/system/restart-altserver.service
    echo "" | sudo tee -a /etc/systemd/system/restart-altserver.service > /dev/null

    echo "[Unit]
Description=restart all altserver service on reboot
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/altserver/restart-altserver.sh
Restart=on-failure

[Install]
WantedBy=default.target
" | sudo tee -a /etc/systemd/system/restart-altserver.service > /dev/null

    echo "Done creating daemon!"

    echo "Enabling daemon..."
    sudo systemctl daemon-reload
    sudo systemctl enable netmuxd
    sudo systemctl enable altserver
    sudo systemctl enable restart-altserver
    echo "Enabled daemon!"

    # echo "Starting server..."
    # sleep 5
    # sudo systemctl restart restart-altserver
    # sleep 5
    # echo "AltServer started!"
    echo -e "You need to reboot to use AltServer\n"
    read -p "Press enter to reboot"
    sudo reboot
  elif [ $optsel -eq 2 ]; then
    echo "Restarting..."

    echo "Restarting AltServer and netmuxd..."
    sudo systemctl restart restart-altserver.service
    sleep 10
    echo "Restarted!"
    
    read -p "Press enter to continue"
  elif [ $optsel -eq 3 ]; then
    echo "Updating..."

    echo "Downloading AltServer Linux and netmuxd..."
    wget https://github.com/NyaMisty/AltServer-Linux/releases/download/v0.0.5/AltServer-armv7 -O altserver
    wget https://github.com/jkcoxson/netmuxd/releases/download/v0.1.4/armv7-linux-netmuxd -O netmuxd
    clear
    echo "Downloaded!"

    echo "Changing files permissions..."
    chmod +x altserver
    chmod +x netmuxd
    echo "Changed!"
    
    echo "Moving to /usr/bin..."
    sudo mv altserver /usr/bin/altserver
    sudo mv netmuxd /usr/bin/netmuxd
    echo "Moved AltServer and netmuxd!"
    echo "Done!"
    read -p "Press enter to continue"
  elif [ $optsel -eq 4 ]; then
    echo "Stopping daemon..."
    sudo systemctl stop netmuxd.service
    sudo systemctl stop altserver.service
    sudo systemctl stop restart-altserver.service

    echo "Disabling daemon..."
    sudo systemctl disable netmuxd.service
    sudo systemctl disable altserver.service
    sudo systemctl disable restart-altserver.service

    echo "Removing daemon..."
    sudo rm /etc/systemd/system/netmuxd.service
    sudo rm /etc/systemd/system/altserver.service
    sudo rm /etc/systemd/system/restart-altserver.service
    
    # sudo rm /usr/lib/systemd/system/netmuxd.service
    # sudo rm /usr/lib/systemd/system/altserver.service
    # sudo rm /usr/lib/systemd/system/restart-altserver.service
    
    echo "Reloading daemon"
    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    echo "Removing files"
    cd ~
    rm -rf altserver
    sudo rm /usr/bin/netmuxd
    sudo rm /usr/bin/altserver

    echo "Done!"
    read -p "Press enter to continue"
  elif [ $optsel -eq 5 ]; then
    echo "Bye!"
    exit 0
  else
    echo "Wrong option!"
  fi
done

exit 0
