#!/usr/bin/env bash

set -e
set -x

id
sudo ls  
echo install Geonature
ls
unzip master.zip
cd GeoNature-master
sudo ls
sed -i 's|mon.domaine.com|127.0.0.1|' install/install_all/install_all.ini
sed -i 's|install_sig_layers=true|install_sig_layers=false|' install/install_all/install_all.ini
sed -i 's|install_grid_layer=true|install_grid_layer=false|' install/install_all/install_all.ini
sed -i 's|install_default_dem=true|install_default_dem=false|' install/install_all/install_all.ini
sudo apt update -y

cd install/install_all
./install_all.sh
