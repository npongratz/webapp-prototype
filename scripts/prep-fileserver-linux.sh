#!/bin/bash -eux

# Create directory whose files will be shared by this app
mkdir -p /srv/share

# Move /tmp/share into /srv/
mv /tmp/share /srv

# user vagrant should own everything in /srv/share
chown -R vagrant:vagrant /srv/share

# make fileserver-linux world executable
chmod +x /tmp/fileserver-linux

# move systemd unit to proper location
mv /tmp/fileserver-linux.service /usr/lib/systemd/system/

# register systemd unit for startup at boot
/usr/bin/systemctl enable fileserver-linux.service
