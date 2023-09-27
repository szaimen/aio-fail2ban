#!/bin/bash

if ! mountpoint -q /nextcloud; then
    echo "/nextcloud is not a mountpoint which it must be!"
    exit 1
fi

while ! [ -f /nextcloud/data/nextcloud.log ]; do
    echo "Waiting for /nextcloud/data/nextcloud.log to become available"
    sleep 5
done

cat << FILTER > /etc/fail2ban/filter.d/nextcloud.conf
[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
FILTER

cat << JAIL > /etc/fail2ban/jail.d/nextcloud.local
[nextcloud]
backend = auto
enabled = true
port = 80,443,8080,8443,3478
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 86400
findtime = 43200
logpath = /nextcloud/data/nextcloud.log
chain=DOCKER-USER
JAIL

fail2ban-server -f --logtarget stderr --loglevel info 
