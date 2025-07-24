#!/usr/bin/env bash

#merge script

echo "Script Start: Merge OverlayFS into NTFS Drive" | systemd-cat -t sysDSyncSteamb4Shutdown

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo. Exiting." | systemd-cat -t sysDSyncSteamb4Shutdown
   exit 1
fi

# Get the directory of the current script
SCRIPT_DIR="$(dirname "$0")"


#check if disk space in layer is less than free space on drive
amtinLayer=$(du -c -d 0 /mnt/winOverlay/SSDWinUpper | grep "total" | awk '{printf "%s",$1}')
amtFreeOnDrive=$(df --total | grep "/mnt/winOverlay/SSDWinLower" | awk '{printf "%s",$4}')

printf "Amount in layer: %s\n" "$amtinLayer" | systemd-cat -t sysDSyncSteamb4Shutdown
printf "Amount free on drive: %s\n" "$amtFreeOnDrive" | systemd-cat -t sysDSyncSteamb4Shutdown


if [[ $amtinLayer -gt $amtFreeOnDrive ]]
   then
      echo "Not enough space on drive to merge changes, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
      exit 1
fi


echo "unmounting layers"  | systemd-cat -t sysDSyncSteamb4Shutdown
sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win


echo "unmount lower read only ntfs drives"  | systemd-cat -t sysDSyncSteamb4Shutdown
sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSDWinLower

#check that the the unmounting was successful
if mountpoint /mnt/winOverlay/SSDWinLower; then
    echo "SSDWinLower is still mounted, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

if mountpoint /mnt/winOverlay/SSD2WinLower; then
    echo "SSD2WinLower is still mounted, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

#mount the upper layers read write
sudo mount UUID=82C425D7C425CDEB /mnt/winOverlay/SSDWinLower -o rw,windows_names,prealloc
sleep 1

if(echo $?); then
    echo "Mounted SSDWinLower as read write, continuing" | systemd-cat -t sysDSyncSteamb4Shutdown
else
    echo "Failed to mount SSDWinLower as read write, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

sudo mount UUID=78DBFD1A57D3E447 /mnt/winOverlay/SSD2WinLower -o rw,windows_names,prealloc
sleep 1

if(echo $?); then
    echo "Mounted SSD2WinLower as read write, continuing" | systemd-cat -t sysDSyncSteamb4Shutdown
else
    echo "Failed to mount SSD2WinLower as read write, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi



echo "use overlayfs tools to merge changes"  | systemd-cat -t sysDSyncSteamb4Shutdown
sudo $SCRIPT_DIR/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/ -u //mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/ -f
sudo $SCRIPT_DIR/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/ -f

echo "Any updates to Windows Steam Library have been merged onto the NTFS partition."  | systemd-cat -t sysDSyncSteamb4Shutdown
exit 0




