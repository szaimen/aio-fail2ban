#!/bin/bash

# Fix socket
rm -f /run/fail2ban/*

if ! mountpoint -q /nextcloud; then
    echo "/nextcloud is not a mountpoint which it must be!"
    exit 1
fi

while ! [ -f /nextcloud/data/nextcloud.log ]; do
    echo "Waiting for /nextcloud/data/nextcloud.log to become available"
    sleep 5
done

cat << FILTER > /etc/fail2ban/filter.d/nextcloud.conf
[INCLUDES]
before = common.conf

[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
FILTER

cat << JAIL > /etc/fail2ban/jail.d/nextcloud-host.local
[nextcloud-host]
enabled = true
port = 80,443,8080,8443,3478
protocol = tcp,udp
filter = nextcloud
banaction = %(banaction_allports)s
maxretry = 3
bantime = 14400
findtime = 14400
logpath = /nextcloud/data/nextcloud.log
# chain=DOCKER-USER
ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 fd00::/8 ::1
JAIL

rm -f /etc/fail2ban/jail.d/nextcloud.local
cp /etc/fail2ban/jail.d/nextcloud-host.local /etc/fail2ban/jail.d/nextcloud.local
sed -i "s|\[nextcloud-host\]|\[nextcloud\]|" /etc/fail2ban/jail.d/nextcloud.local
sed -i "s|^# chain|chain|" /etc/fail2ban/jail.d/nextcloud.local

if [ -f /vaultwarden/vaultwarden.log ]; then
    echo "Configuring vaultwarden for logs"
    # Vaultwarden conf
    cat << BW_CONF > /etc/fail2ban/filter.d/vaultwarden.conf
[INCLUDES]
before = common.conf

[Definition]
failregex = ^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
ignoreregex =
BW_CONF

    # Vaultwarden jail
    cat << BW_JAIL_CONF > /etc/fail2ban/jail.d/vaultwarden-host.local
[vaultwarden-host]
enabled = true
port = 80,443,8812
protocol = tcp,udp
filter = vaultwarden
banaction = %(banaction_allports)s
logpath = /vaultwarden/vaultwarden.log
maxretry = 3
bantime = 14400
findtime = 14400
# chain=DOCKER-USER
ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 fd00::/8 ::1
BW_JAIL_CONF

    rm -f /etc/fail2ban/jail.d/vaultwarden.local
    cp /etc/fail2ban/jail.d/vaultwarden-host.local /etc/fail2ban/jail.d/vaultwarden.local
    sed -i "s|\[vaultwarden-host\]|\[vaultwarden\]|" /etc/fail2ban/jail.d/vaultwarden.local
    sed -i "s|^# chain|chain|" /etc/fail2ban/jail.d/vaultwarden.local

    # Vaultwarden-admin conf
    cat << BWA_CONF > /etc/fail2ban/filter.d/vaultwarden-admin.conf
[INCLUDES]
before = common.conf

[Definition]
failregex = ^.*Invalid admin token\. IP: <ADDR>.*$
ignoreregex =
BWA_CONF

    # Vaultwarden-admin jail
    cat << BWA_JAIL_CONF > /etc/fail2ban/jail.d/vaultwarden-admin-host.local
[vaultwarden-admin-host]
enabled = true
port = 80,443,8812
protocol = tcp,udp
filter = vaultwarden-admin
banaction = %(banaction_allports)s
logpath = /vaultwarden/vaultwarden.log
maxretry = 3
bantime = 14400
findtime = 14400
# chain=DOCKER-USER
ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 fd00::/8 ::1
BWA_JAIL_CONF

    rm -f /etc/fail2ban/jail.d/vaultwarden-admin.local
    cp /etc/fail2ban/jail.d/vaultwarden-admin-host.local /etc/fail2ban/jail.d/vaultwarden-admin.local
    sed -i "s|\[vaultwarden-admin-host\]|\[vaultwarden-admin\]|" /etc/fail2ban/jail.d/vaultwarden-admin.local
    sed -i "s|^# chain|chain|" /etc/fail2ban/jail.d/vaultwarden-admin.local
fi

if [ -d /jellyfin/log ]; then
    echo "Configuring jellyfin for logs"
    # Jellyfin conf
    cat << JELLYFIN_CONF > /etc/fail2ban/filter.d/jellyfin.conf
[INCLUDES]
before = common.conf

[Definition]
failregex = ^.*Authentication request for .* has been denied \(IP: "<ADDR>"\)\.
JELLYFIN_CONF

    # Jellyfin jail
    cat << JELLYFIN_JAIL_CONF > /etc/fail2ban/jail.d/jellyfin-host.local
[jellyfin-host]
enabled = true
port = 80,443,8096,8920,1900,7359
protocol = tcp,udp
filter = jellyfin
banaction = %(banaction_allports)s
maxretry = 3
bantime = 86400
findtime = 43200
logpath = /jellyfin/log/*.log
# chain=DOCKER-USER
ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 fd00::/8 ::1
JELLYFIN_JAIL_CONF

    rm -f /etc/fail2ban/jail.d/jellyfin.local
    cp /etc/fail2ban/jail.d/jellyfin-host.local /etc/fail2ban/jail.d/jellyfin.local
    sed -i "s|\[jellyfin-host\]|\[jellyfin\]|" /etc/fail2ban/jail.d/jellyfin.local
    sed -i "s|^# chain|chain|" /etc/fail2ban/jail.d/jellyfin.local
fi

if [ -d /jellyseerr/logs ]; then
    echo "Configuring jellyseerr for logs"
    # Jellyseerr conf
    cat << JELLYSEERR_CONF > /etc/fail2ban/filter.d/jellyseerr.conf
[INCLUDES]
before = common.conf

[Definition]
failregex = .*\[warn\]\[API\]\: Failed sign-in attempt.*"ip":"<HOST>"
JELLYSEERR_CONF

    # Jellyseerr jail
    cat << JELLYSEERR_JAIL_CONF > /etc/fail2ban/jail.d/jellyseerr-host.local
[jellyseerr-host]
enabled = true
port = 80,443,5055
protocol = tcp,udp
filter = jellyseerr
banaction = %(banaction_allports)s
maxretry = 3
bantime = 86400
findtime = 43200
logpath = /jellyseerr/logs/*.log
# chain=DOCKER-USER
ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 fd00::/8 ::1
JELLYSEERR_JAIL_CONF

    rm -f /etc/fail2ban/jail.d/jellyseerr.local
    cp /etc/fail2ban/jail.d/jellyseerr-host.local /etc/fail2ban/jail.d/jellyseerr.local
    sed -i "s|\[jellyseerr-host\]|\[jellyseerr\]|" /etc/fail2ban/jail.d/jellyseerr.local
    sed -i "s|^# chain|chain|" /etc/fail2ban/jail.d/jellyseerr.local
fi

fail2ban-server -f --logtarget stderr --loglevel info 
