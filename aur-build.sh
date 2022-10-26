RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=nobody
fi

mkdir -p ./build
cd build
echo "Building $1"
curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1" -o PKGBUILD
sudo -u $RUN_AS makepkg
mv *.tar.zst ../
rm -rf *
cd ..
rm -rf build
