sudo dnf install meson ninja-build
sudo pacman -S meson ninja   
cd overlayfs-tools
meson setup builddir && cd builddir
meson compile
mv builddir/* ../overlaybuild/