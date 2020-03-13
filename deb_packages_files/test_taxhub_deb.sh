sudo apt remove -y --purge taxhub 
cd taxhub
# rm -r debian/taxhub
dpkg-buildpackage --no-sign --build=binary
cd ..
sudo apt install ./taxhub_0.0.1-1_amd64.deb
