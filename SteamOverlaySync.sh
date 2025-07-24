#!/usr/bin/env bash

#merge script

#
# TODO Wait to make sure filesystems are not busy
#

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo. Exiting."
   exit 1
fi

# Get the directory of the current script
    SCRIPT_DIR="$(dirname "$0")"


exitRemount(){
   sudo mount -a && sudo systemctl daemon-reload
   exit 3
}



killprocesses() {
    # Check if any processes are using the mount points
    local mount_points=("/mnt/SSDWin" "/mnt/SSD2Win" "/mnt/winOverlay/SSDWinLower" "/mnt/winOverlay/SSD2WinLower")
    for mount_point in "${mount_points[@]}"; do
        fuser -vcuk "$mount_point"
    done

    # Wait a moment to ensure processes have terminated
    sleep 2
    #check again
    for mount_point in "${mount_points[@]}"; do
        if lsof +D "$mount_point" &>/dev/null; then
            echo "Processes are using the mount point $mount_point. Please close them before proceeding."
            exit 1
        fi
    done
}

checkallmounts () {
    # Check if the required mounts are present
    if ! mountpoint /mnt/SSDWin || ! mountpoint /mnt/SSD2Win || ! mountpoint /mnt/winOverlay/SSDWinLower || ! mountpoint /mnt/winOverlay/SSD2WinLower; then
        exit 1 
    fi
}

checkfinalOverlayMounts () {
    # Check if the required mounts are present
    if ! mountpoint /mnt/SSDWin || ! mountpoint /mnt/SSD2Win; then
        exit 1 
    fi
}




if(checkallmounts); then
    echo "All mounts are present, continuing"
else
    exitRemount
fi

#check if disk space in layer is less than free space on drive
amtinLayer=$(du -c -d 0 /mnt/winOverlay/SSDWinUpper | grep "total" | awk '{printf "%s",$1}')
amtFreeOnDrive=$(df --total | grep "/mnt/winOverlay/SSDWinLower" | awk '{printf "%s",$4}')

printf "Amount in layer: %s\n" "$amtinLayer"
printf "Amount free on drive: %s\n" "$amtFreeOnDrive" 


if [[ $amtinLayer -gt $amtFreeOnDrive ]]
   then
      echo "Not enough space on drive to merge changes, exiting"
      exitRemount
fi

echo "Closing Steam"
killall steam

#kill everything using the mount points
echo "Killing processes using mount points"

killprocesses

sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win

sleep 2

if(checkfinalOverlayMounts); then
    echo "Overlay mounts unmounted, continuing"
else
    echo "Overlay mounts still exist and were not unmounted properly, exiting"
    exitRemount
fi

echo "unmount lower read only ntfs drives"
sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

sleep 2

#check that the the unmounting was successful
if mountpoint /mnt/winOverlay/SSDWinLower; then
    echo "SSDWinLower is still mounted, exiting"
    exitRemount
fi

if mountpoint /mnt/winOverlay/SSD2WinLower; then
    echo "SSD2WinLower is still mounted, exiting"
    exitRemount
fi


sudo mount UUID=82C425D7C425CDEB /mnt/winOverlay/SSDWinLower -o rw,windows_names,prealloc
sleep 1

if(echo $?); then
    echo "Mounted SSDWinLower as read write, continuing"
else
    echo "Failed to mount SSDWinLower as read write, exiting"
    exitRemount
fi

#check that there is enough space on the drive

sudo mount UUID=78DBFD1A57D3E447 /mnt/winOverlay/SSD2WinLower -o rw,windows_names,prealloc
sleep 1

if(echo $?); then
    echo "Mounted SSD2WinLower as read write, continuing"
else
    echo "Failed to mount SSD2WinLower as read write, exiting"
    exitRemount
fi



echo "use overlayfs tools to merge changes"
sudo $SCRIPT_DIR/overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/ -u //mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/ -f
sudo $SCRIPT_DIR/overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/ -f



read -n 1 -s -r -p "Press any key to continue if no errors have occurred in overlay merge"

#make sure we are in root directory to avoid issues with unmounting

cd /

sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win

sleep 2

sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

sleep 2

#check that the the unmounting was successful
if mountpoint /mnt/winOverlay/SSDWinLower; then
    echo "SSDWinLower is still writable, exiting"
    exitRemount
fi

if mountpoint /mnt/winOverlay/SSD2WinLower; then
    echo "SSD2WinLower is still writable, exiting"
    exitRemount
fi




echo "remount drives from fstab"
exitRemount




