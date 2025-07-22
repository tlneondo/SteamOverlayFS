sudo mkdir /mnt/winOverlay
cd /mnt/winOverlay
sudo mkdir SSDWinlower SSDWinupper SSD2Winlower SSD2Winupper SSDWinMerge SSD2WinMerge

#mounts for lower readonly ntfs
UUID=82C425D7C425CDEB /mnt/winOverlay/SSDWinlower ntfs ro,windows_names,prealloc 0 0
UUID=... /mnt/winOverlay/SSD2Winlower ntfs ro,windows_names,prealloc 0 0

##set up btrfs subvolume for upper layer
sudo btrfs subvolume create 
sudo btrfs subvolume create 

UUID=... /mnt/winOverlay/SSDWinupper btrfs defaults 0 0
UUID=... /mnt/winOverlay/SSD2Winupper btrfs defaults 0 0

overlay /mnt/SSDWin overlay noauto,x-systemd.automount,lowerdir=/mnt/winOverlay/SSDWinlower,upperdir=/mnt/winOverlay/SSDWinupper,workdir=/mnt/winOverlay/SSDWinMerge
overlay /mnt/SSD2Win overlay noauto,x-systemd.automount,lowerdir=/mnt/winOverlay/SSD2Winlower,upperdir=/mnt/winOverlay/SSD2Winupper,workdir=/mnt/winOverlay/SSD2WinMerge


#merge script

#
# TODO Wait to make sure filesystems are not busy
#

#close steam
killall steam

#unmount merged folders
sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win

#unmount lower readonly ntfs
sudo umount /mnt/winOverlay/SSDWinlower
sudo umount /mnt/winOverlay/SSD2Winlower

#mount NTFS as read write
sudo mount rw /mnt/winOverlay/SSDWinlower
sudo mount rw /mnt/winOverlay/SSD2Winlower

#use overlayfs tools to merge changes
sudo overlay merge /mnt/winOverlay/SSDWinupper/ /mnt/winOverlay/SSDWinlower/
sudo overlay merge /mnt/winOverlay/SSD2Winupper/ /mnt/winOverlay/SSD2Winlower/

#unmount writable ntfs
sudo umount /mnt/winOverlay/SSDWinlower
sudo umount /mnt/winOverlay/SSD2Winlower

#wipe upper layers
sudo rm -fr /mnt/winOverlay/SSDWinupper/*
sudo rm -fr /mnt/winOverlay/SSD2Winupper/*

#unmount upper layers
sudo umount /mnt/winOverlay/SSDWinupper
sudo umount /mnt/winOverlay/SSD2Winupper

#remount drives from fstab
sudo mount -a




