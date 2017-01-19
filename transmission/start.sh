#!/bin/sh

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# This script will be called with tun/tap device name as parameter 1, and local IP as parameter 4
# See https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html (--up cmd)
echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to the ip of $1 : $4"
export TRANSMISSION_BIND_ADDRESS_IPV4=$4

echo "Generating transmission settings.json from env variables"
# Ensure TRANSMISSION_HOME is created
mkdir -p ${TRANSMISSION_HOME}
dockerize -template /etc/transmission/settings.tmpl:${TRANSMISSION_HOME}/settings.json /bin/true

if [ ! -e "/dev/random" ]; then
  # Avoid "Fatal: no entropy gathering module detected" error
  echo "INFO: /dev/random not found - symlink to /dev/urandom"
  ln -s /dev/urandom /dev/random
fi

. /etc/transmission/userSetup.sh

echo "STARTING TRANSMISSION"
#exec sudo -u ${RUN_AS} /usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile ${TRANSMISSION_HOME}/transmission.log &
exec /usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile ${TRANSMISSION_HOME}/transmission.log &

if [ "$OPENVPN_PROVIDER" = "PIA" ]
then
    echo "STARTING PORT UPDATER"
    exec /etc/transmission/periodicUpdates.sh $4 &
else
    echo "NO PORT UPDATER FOR THIS PROVIDER"
fi

echo "Transmission startup script complete."

# if the /data/couchpotato directory doesn't contain anything, then start CouchPotatoServer, stop it,
# and update the settings so that the wizard doesn't run (which in the current version seems buggy).
directory="/data/.config/couchpotato"
if [ ! "$(ls -A $directory)" ]; then
    /usr/bin/python2.7 /opt/CouchPotatoServer/CouchPotato.py --data_dir=/data/.config/couchpotato --console_log & \
    sleep 10
    kill $(pidof python2.7)
    sleep 3
    sed -i "s/show_wizard = 1/show_wizard = 0/" /data/.config/couchpotato/settings.conf 
    /usr/bin/python2.7 /opt/CouchPotatoServer/CouchPotato.py --data_dir=/data/.config/couchpotato --console_log &
else
    /usr/bin/python2.7 /opt/CouchPotatoServer/CouchPotato.py --data_dir=/data/.config/couchpotato --console_log &
fi

echo "CouchPotato startup script complete."
# if the /data/couchpotato directory doesn't contain anything, then start CouchPotatoServer, stop it,
# and update the settings so that the wizard doesn't run (which in the current version seems buggy).
directory="/data/.config/sickrage"
if [ ! "$(ls -A $directory)" ]; then
    /usr/bin/python2.7 /opt/SickRage/SickBeard.py --datadir=/data/.config/sickrage & \
    sleep 10
    kill $(pidof python2.7)
    sleep 3
#    sed -i "s/show_wizard = 1/show_wizard = 0/" /data/couchpotato/settings.conf
    /usr/bin/python2.7 /opt/SickRage/SickBeard.py --datadir=/data/.config/sickrage &
else
    /usr/bin/python2.7 /opt/SickRage/SickBeard.py --datadir=/data/.config/sickrage &
fi
