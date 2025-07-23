#merge script

#
# TODO Wait to make sure filesystems are not busy
#

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo. Exiting."
   exit 1
fi

checkallmounts () {
    # Check if the required mounts are present
    if ! mountpoint -q /mnt/SSDWin || ! mountpoint -q /mnt/SSD2Win || ! mountpoint -q /mnt/winOverlay/SSDWinLower || ! mountpoint -q /mnt/winOverlay/SSD2WinLower; then
        echo "One or more required mounts are not present. Please ensure all mounts are active."
        exit 1 
    fi
}

checkfinalOverlayMounts () {
    # Check if the required mounts are present
    if ! mountpoint -q /mnt/SSDWin || ! mountpoint -q /mnt/SSD2Win; then
        echo "Overlay mounts Do not exist"
        exit 1 
    fi
}


checklowermounts () {
    # Check if the required mounts are present
    if ! mountpoint -q /mnt/winOverlay/SSDWinLower || ! mountpoint -q /mnt/winOverlay/SSD2WinLower; then
        echo "One or more required mounts are not present. Please ensure all mounts are active."
        exit 1 
    fi
}

if(checkallmounts); then
    echo "All mounts are present, continuing"
else
    exit 1
fi


echo "Closing Steam"
killall steam

read -n 1 -s -r -p "Press any key when Steam is closed"

echo "unmount merged folders"
sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win

if(!checkfinalOverlayMounts); then
    echo "Overlay mounts unmounted, continuing"
else
    echo "Overlay mounts still exist and were not unmounted properly, exiting"
    exit 1
fi

echo "mount NTFS as read write"

sudo mount UUID=82C425D7C425CDEB /mnt/winOverlay/SSDWinLower -o remount,rw,windows_names,prealloc
sudo mount UUID=78DBFD1A57D3E447 /mnt/winOverlay/SSD2WinLower -o remount,rw,windows_names,prealloc

read -n 1 -s -r -p "Press any key if drives mounted correctly"

echo "use overlayfs tools to merge changes"
sudo ./overlay merge -l /mnt/winOverlay/SSDWinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSDWinUpper/SteamLibrary/steamapps/ -f
sudo ./overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/ -f

read -n 1 -s -r -p "Press any key to no errors have occurred in overlay merge"

cd /

echo "unmount writable ntfs"
sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

read -n 1 -s -r -p "Press any key when writable lower drives are unmounted"


echo "remount drives from fstab"
sudo mount -a
sudo systemctl daemon-reload




