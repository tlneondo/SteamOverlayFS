sudo dnf install meson ninja-build
cd overlayfs-tools
meson setup builddir && cd builddir
meson compile
cd ../