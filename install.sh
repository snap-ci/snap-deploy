#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd)"
cd $SCRIPT_DIR

export NOKOGIRI_USE_SYSTEM_LIBRARIES=1
export PATH="/opt/local/ruby/2.2.2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# change ownership to nobody to not screw up things (even accidentally)
chown nobody -R $SCRIPT_DIR

# perform the bundle install
su -l nobody -s /bin/bash -c "cd $SCRIPT_DIR && env PATH=$PATH NOKOGIRI_USE_SYSTEM_LIBRARIES=1 $(which bundle) install --local --standalone --clean"

# change ownership back to root
chown root -R $SCRIPT_DIR
