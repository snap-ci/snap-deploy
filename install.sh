#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd)"

cd $SCRIPT_DIR

# change ownership to nobody to not screw up things (even accidentally)
chown nobody.nobody -R $SCRIPT_DIR

# perform the bundle install
sudo -E -u nobody NOKOGIRI_USE_SYSTEM_LIBRARIES=1 PATH="/opt/local/ruby/2.0.0-p353/bin:$PATH" $(which bundle) install --local --standalone --clean

# change ownership back to root
chown root.root -R $SCRIPT_DIR
