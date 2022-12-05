#!/bin/bash

apt update && apt upgrade -y && apt install nginx nano curl -y
systemctl stop apache2
sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common
apt autoremove

read -p "Enter your domain: " domain
read -p "Enter your email address: " email
read -p "Enter UUID: " uuid

if [[ "server_name _;" != "" && $domain != "" ]]; then
sed -i "s/server_name _;/server_name $domain;/" /etc/nginx/sites-available/default
fi

systemctl restart nginx

apt install python3 python3-venv libaugeas0 -y
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-nginx
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

certbot certonly --nginx -q --preferred-challenges http --agree-tos --email $email -d $domain
certbot renew --dry-run

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

:> /usr/local/etc/xray/config.json

cat <<EOT >> /usr/local/etc/xray/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "level": 0,
                        "email": "$email"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/vless-tls",
                        "dest": 1234,
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/letsencrypt/live/$domain/fullchain.pem",
                            "keyFile": "/etc/letsencrypt/live/$domain/privkey.pem"
                        }
                    ]
                }
            }
        },
        {
            "port": 1234,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "level": 0,
                        "email": "$email"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/vless-tls"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOT

wget https://raw.githubusercontent.com/CTechDidik/BBR-CTech/main/BBR-CTechDidik.sh && chmod +x BBR-CTechDidik.sh && sed -i -e 's/\r$//' BBR-CTechDidik.sh && screen -S BBR-CTechDidik ./BBR-CTechDidik.sh

systemctl restart xray

echo "VLESS WS"
echo "vless://$uuid@$domain:443?path=%2Fvless-tls&security=tls&encryption=none&type=ws&sni=sg.hasyi.me#hasyiVPN"
echo "-----------------------------------------------------------------------------------------------------"
echo "VLESS TCP"
echo "vless://$uuid@$domain:443?security=tls&encryption=none&type=tcp&sni=sg.hasyi.me#hasyiVPN"
