#!/usr/bin/pkexec /bin/bash 

#Todo

#flow control for if running as service or manually

#try catch for drive mounting

echo "Script Start: Merge OverlayFS into NTFS Drive" | systemd-cat -t sysDSyncSteamb4Shutdown

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo. Exiting." | systemd-cat -t sysDSyncSteamb4Shutdown
   exit 1
fi

# Get the directory of the current script and set the overlay location
SCRIPT_DIR="$(dirname "$0")"
OVERLAYLOCATION="$HOME/Projects/SteamOverlayFS/"
SCRIPT_RUN_TYPE=0
#1 = manual, 2 = at shutdown


#check args
if [[ $# -ne 0 ]]; then
    echo "No arguments expected, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 99
fi

if [[$@[0]] == "manual" || $@[0] == "--manual" || $@[0] == "-m"]]; then
    echo "Running Steam Sync Manually" | systemd-cat -t sysDSyncSteamb4Shutdown
    SCRIPT_RUN_TYPE=1
fi

if [[$@[0]] == "atshutdown" || $@[0] == "--atshutdown" || $@[0] == "-as"]]; then
    echo "Running Steam Sync At Shutdown" | systemd-cat -t sysDSyncSteamb4Shutdown
    SCRIPT_RUN_TYPE=2
fi


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
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/common/ -u /mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/common/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/workshop/ -u /mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/workshop/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/temp/ -u /mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/temp/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/downloads/ -u /mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/downloads/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/sourcemods/ -u /mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/sourcemods/ -f

sudo rsync -avr /mnt/winOverlay/SSD2WinUpper/Media/Games/Steam/steamapps/*.acf /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/ --remove-source-files

suro rm -rf /mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/*

sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/common/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/common/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/workshop/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/workshop/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/temp/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/temp/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/downloads/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/downloads/ -f
sudo $OVERLAYLOCATION/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/sourcemods/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/sourcemods/ -f

sudo rsync -avr /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/*.acf /mnt/winOverlay/SSDWinLower/SteamLibrary/steamapps/ --remove-source-files

suro rm -rf /mnt/winOverlay/SSD2WinUpper/Media/Games/Steam/steamapps/*

echo "Any updates to Windows Steam Library have been merged onto the NTFS partition."  | systemd-cat -t sysDSyncSteamb4Shutdown
exit 0




