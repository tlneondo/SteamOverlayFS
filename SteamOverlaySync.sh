#!/usr/bin/env bash

#merge script

#
# TODO Wait to make sure filesystems are not busy
#

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo. Exiting."
   exit 1
fi

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
    if ! mountpoint -q /mnt/SSDWin || ! mountpoint -q /mnt/SSD2Win || ! mountpoint -q /mnt/winOverlay/SSDWinLower || ! mountpoint -q /mnt/winOverlay/SSD2WinLower; then
        echo "One or more required mounts are not present. Please ensure all mounts are active."
        exitRemount 
    fi
}

checkfinalOverlayMounts () {
    # Check if the required mounts are present
    if ! mountpoint -q /mnt/SSDWin || ! mountpoint -q /mnt/SSD2Win; then
        echo "Overlay mounts Do not exist"
        exitRemount 
    fi
}


checklowermounts () {
    # Check if the required mounts are present
    if ! mountpoint -q /mnt/winOverlay/SSDWinLower || ! mountpoint -q /mnt/winOverlay/SSD2WinLower; then
        echo "One or more required mounts are not present. Please ensure all mounts are active."
        exitRemount 
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

echo "unmount merged folder overlays"
sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win



if(checkfinalOverlayMounts); then
    echo "Overlay mounts unmounted, continuing"
else
    echo "Overlay mounts still exist and were not unmounted properly, exiting"
    exitRemount
fi

echo "unmount lower read only ntfs drives"
sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

if(checklowermounts); then
    echo "read only lower mounts unmounted, continuing"
else
    echo "read only lower mounts still exist and were not unmounted properly, exiting"
    exitRemount
fi

echo "mount NTFS as read write"

sudo mount UUID=82C425D7C425CDEB /mnt/winOverlay/SSDWinLower -o rw,windows_names,prealloc

if(echo $?); then
    echo "Mounted SSDWinLower as read write, continuing"
else
    echo "Failed to mount SSDWinLower as read write, exiting"
    exitRemount
fi

#check that there is enough space on the drive
#TODO

sudo mount UUID=78DBFD1A57D3E447 /mnt/winOverlay/SSD2WinLower -o rw,windows_names,prealloc

if(echo $?); then
    echo "Mounted SSD2WinLower as read write, continuing"
else
    echo "Failed to mount SSD2WinLower as read write, exiting"
    exitRemount
fi



echo "use overlayfs tools to merge changes"
sudo ./overlay merge -l /mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps/ -u //mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps/ -f
sudo ./overlay merge -l /mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/ -u /mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps/ -f



read -n 1 -s -r -p "Press any key to continue if no errors have occurred in overlay merge"

#make sure we are in root directory to avoid issues with unmounting
cd /

echo "unmount writable ntfs"
sudo umount /mnt/winOverlay/SSDWinLower
sudo umount /mnt/winOverlay/SSD2WinLower

#check that unmounts were successful
checklowermounts()
if(! checklowermounts); then
    echo "Writable lower mounts unmounted, continuing"
else
    echo "Writable lower mounts still exist and were not unmounted properly, exiting"
    exitRemount
fi



echo "remount drives from fstab"
exitRemount




