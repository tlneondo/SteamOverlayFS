#merge script

#
# TODO Wait to make sure filesystems are not busy
#

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo. Exiting."
   exit 1
fi


echo "Closing Steam"
killall steam

sleep 10s

echo"unmount merged folders"
sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win

sleep 10s

echo "unmount lower readonly ntfs"

sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

sleep 10s

echo "mount NTFS as read write"

sudo mount UUID=82C425D7C425CDEB /mnt/winOverlay/SSDWinLower -o rw
sudo mount UUID=78DBFD1A57D3E447 /mnt/winOverlay/SSD2WinLower -o rw

sleep 15s

echo "use overlayfs tools to merge changes"
sudo ./overlay merge -l /mnt/winOverlay/SSDWinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSDWinUpper/SteamLibrary/steamapps/ -f
sudo ./overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/ -f

echo "unmount writable ntfs"
sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

sleep 15s


sleep 15s

echo "remount drives from fstab"
sudo mount -a
sudo systemctl daemon-reload




