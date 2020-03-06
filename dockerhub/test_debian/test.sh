#!/usr/bin/env bash

# apt update
# apt install -y sudo python3.5
# command -v python3.5

# sudo apt install -y git
command -v python
command -v python3.5
git clone https://github.com/PnX-SI/GeoNature-packaging.git
cd GeoNature-packaging
git checkout integration-testing
cp settings.ini.sample settings.ini
./integration_tests.sh setup
./integration_tests.sh run_all