#!/bin/bash
export PATH="/opt/local/ruby/2.0.0-p598/bin:$PATH"

export NOKOGIRI_USE_SYSTEM_LIBRARIES=1

while read line; do
  [[ -n ${SNAP_CI} || -n ${GO_SERVER_URL} ]] || echo -ne "Doing $((C++)) things...\r"
done < <(bundle check || bundle install --local --standalone --clean )
