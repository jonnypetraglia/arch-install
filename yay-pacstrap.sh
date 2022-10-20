INPUT_FILE=${2:-/dev/stdin}         #Argument 2 from command line is the input file

while read -r pkg
do
    mkdir $pkg
    curl -o ./$pkg/PKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg"
    cd $pkg
    makepkg
    cp "$pkg/*.pkg.tar.zst" ./
done < "$INPUT_FILE"


pacman -U *.pkg.tar.zst

