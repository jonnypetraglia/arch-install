set -e
set -o pipefail

INPUT_FILE=${2:-/dev/stdin}         #Argument 2 from command line is the input file

mkdir -p tmpdir
cd tmpdir

# https://github.com/archlinux/arch-install-scripts/blob/master/pacstrap.in

while read -r pkg
do
    curl -o PKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg"
    makepkg
    mv *.pkg.tar.zst ..
    rm -rf *
done < "$INPUT_FILE"

cd ..
rm -rf tmpdir
