#!/bin/sh

#  install_helper.sh
#  shadowsocks
#
#  Created by clowwindy on 14-3-15.

cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "/Library/Application Support/RalletsX/"
sudo cp Rallets "/Library/Application Support/RalletsX/Rallets_sysconf"
sudo chown root:admin "/Library/Application Support/RalletsX/Rallets_sysconf"
sudo chmod +s "/Library/Application Support/RalletsX/Rallets_sysconf"

echo done