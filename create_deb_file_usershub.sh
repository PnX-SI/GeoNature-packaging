# creation du venv
python3 -m venv /tmp/venv
source /tmp/venv/bin/activate
pip install -r requirements.txt

echo "Create usershub build"
./manage.py build usershub 0.0.1 1 --keep-temp-dir --taxhub-repo-uri /home/pnc-si/dev/TaxHub --usershub-repo-uri /home/pnc-si/dev/UsersHub --geonature-repo-uri ~/dev/GeoNature --usershub-checkout develop

deactivate

echo "Purge installation"
sudo apt purge -y usershub

echo "Installation"
sudo apt install ./build/usershub_0.0.1-1_amd64.deb
