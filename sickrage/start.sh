#!/bin/bash

# if the /data/couchpotato directory doesn't contain anything, then start CouchPotatoServer, stop it,
# and update the settings so that the wizard doesn't run (which in the current version seems buggy).
#directory="/data/sickrage"
if [ ! "$(ls -A $directory)" ]; then
    /usr/bin/python2.7 /opt/SickRage/SickBeard.py --datadir /data/sickrage \ #--console_log & \
    sleep 10
    kill $(pidof python2.7)
    sleep 3
#    sed -i "s/show_wizard = 1/show_wizard = 0/" /data/couchpotato/settings.conf
    /usr/bin/python2.7 /opt/SickRage/SickBeard.py --datadir /data/sickrage 
else
    /usr/bin/python2.7 /opt/SickRage/SickBeard.py --datadir /data/sickrage
fi
