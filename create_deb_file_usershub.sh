./manage.py build usershub 0.0.1 1 --keep-temp-dir --taxhub-repo-uri /home/pnc-si/dev/TaxHub --usershub-repo-uri /home/pnc-si/dev/UsersHub --geonature-repo-uri ~/dev/GeoNature --usershub-checkout develop

sudo apt purge -y usershub
sudo apt install ./build/usershub_0.0.1-1_amd64.deb
