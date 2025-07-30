#!/usr/bin/pkexec /bin/bash 



echo "Script Start: Merge OverlayFS into NTFS Drive" | systemd-cat -t sysDSyncSteamb4Shutdown

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo or pkexec. Exiting." | systemd-cat -t sysDSyncSteamb4Shutdown
   exit 1
fi

# Get the directory of the current script and set the overlay location
SCRIPT_DIR="$(dirname "$0")"
OVERLAYTOOLSLOCATION="$HOME/Projects/SteamOverlayFS/"

UPPERLOCATIONS=(
    "/mnt/winOverlay/SSDWinUpper"
    "/mnt/winOverlay/SSD2WinUpper"
)
LOWERLOCATIONS=(
    "/mnt/winOverlay/SSDWinLower"
    "/mnt/winOverlay/SSD2WinLower"
)
MERGELOCATIONS=(
    "/mnt/winOverlay/SSDWinMerge"
    "/mnt/winOverlay/SSD2WinMerge"
)

#check that length of arrays are equal
if [[ ${#UPPERLOCATIONS[@]} -ne ${#LOWERLOCATIONS[@]} ]] || [[ ${#UPPERLOCATIONS[@]} -ne ${#MERGELOCATIONS[@]} ]]; then
    echo "Error: UPPERLOCATIONS, LOWERLOCATIONS, and MERGELOCATIONS arrays must have the same length." | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

SCRIPT_RUN_TYPE=0
#1 = manual, 2 = at shutdown


function copyFiles(drivenumber)){ 


}



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


#function for disk space check
function checkDiskSpace(driveTop,driveLow) {

    #check if disk space in layer is less than free space on drive
    amtinLayer=$(du -c -d 0 ${driveTop} | grep "total" | awk '{printf "%s",$1}')
    amtFreeOnDrive=$(df --total | grep "${driveLow}" | awk '{printf "%s",$4}')

    printf "Amount in layer: %s\n" "$amtinLayer" | systemd-cat -t sysDSyncSteamb4Shutdown
    printf "Amount free on drive: %s\n" "$amtFreeOnDrive" | systemd-cat -t sysDSyncSteamb4Shutdown


    if [[ $amtinLayer -gt $amtFreeOnDrive ]]
    then
        echo "Failing Merging %s into %s\n" "$driveTop" "$driveLow" | systemd-cat -t sysDSyncSteamb4Shutdown
        echo "Not enough space on drive to merge changes, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
        exit 1
    fi

}


#check drive space in all layers
for i in "${!UPPERLOCATIONS[@]}"; do
    echo "Checking disk space for ${UPPERLOCATIONS[$i]} and ${LOWERLOCATIONS[$i]}" | systemd-cat -t sysDSyncSteamb4Shutdown
    checkDiskSpace "${UPPERLOCATIONS[$i]}" "${LOWERLOCATIONS[$i]}"
done



echo "unmounting layers"  | systemd-cat -t sysDSyncSteamb4Shutdown
sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win


echo "unmount lower read only ntfs drives"  | systemd-cat -t sysDSyncSteamb4Shutdown
sudo umount ${LOWERLOCATIONS[0]}
sudo umount ${LOWERLOCATIONS[0]}

#check that the the unmounting was successful
if mountpoint ${LOWERLOCATIONS[0]}; then
    echo "SSDWinLower is still mounted, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

if mountpoint ${LOWERLOCATIONS[1]}; then
    echo "SSD2WinLower is still mounted, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

#mount the upper layers read write
sudo mount UUID=82C425D7C425CDEB ${LOWERLOCATIONS[0]} -o rw,windows_names,prealloc
sleep 1

if(echo $?); then
    echo "Mounted SSDWinLower as read write, continuing" | systemd-cat -t sysDSyncSteamb4Shutdown
else
    echo "Failed to mount SSDWinLower as read write, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi

sudo mount UUID=78DBFD1A57D3E447 ${LOWERLOCATIONS[1]} -o rw,windows_names,prealloc
sleep 1

if(echo $?); then
    echo "Mounted SSD2WinLower as read write, continuing" | systemd-cat -t sysDSyncSteamb4Shutdown
else
    echo "Failed to mount SSD2WinLower as read write, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 1
fi



echo "use overlayfs tools to merge changes"  | systemd-cat -t sysDSyncSteamb4Shutdown
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[0]}/Media/Games/Steam/steamapps/common/ -u ${UPPERLOCATIONS[0]}/Media/Games/Steam/steamapps/common/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[0]}/Media/Games/Steam/steamapps/workshop/ -u ${UPPERLOCATIONS[0]}/Media/Games/Steam/steamapps/workshop/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[0]}/Media/Games/Steam/steamapps/temp/ -u ${UPPERLOCATIONS[0]}/Media/Games/Steam/steamapps/temp/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[0]}/Media/Games/Steam/steamapps/downloads/ -u ${UPPERLOCATIONS[0]}/Media/Games/Steam/steamapps/downloads/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[0]}/Media/Games/Steam/steamapps/sourcemods/ -u ${UPPERLOCATIONS[0]}/Media/Games/Steam/steamapps/sourcemods/ -f

sudo rsync -avr ${UPPERLOCATIONS[1]}/Media/Games/Steam/steamapps/*.acf ${LOWERLOCATIONS[0]}/Media/Games/Steam/steamapps/ --remove-source-files

suro rm -rf ${UPPERLOCATIONS[0]}/Media/Games/Steam/steamapps/*

sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[1]}/SteamLibrary/steamapps/common/ -u ${UPPERLOCATIONS[1]}/SteamLibrary/steamapps/common/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[1]}/SteamLibrary/steamapps/workshop/ -u ${UPPERLOCATIONS[1]}/SteamLibrary/steamapps/workshop/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[1]}/SteamLibrary/steamapps/temp/ -u ${UPPERLOCATIONS[1]}/SteamLibrary/steamapps/temp/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[1]}/SteamLibrary/steamapps/downloads/ -u ${UPPERLOCATIONS[1]}/SteamLibrary/steamapps/downloads/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${LOWERLOCATIONS[1]}/SteamLibrary/steamapps/sourcemods/ -u ${UPPERLOCATIONS[1]}/SteamLibrary/steamapps/sourcemods/ -f

sudo rsync -avr ${UPPERLOCATIONS[1]}/SteamLibrary/steamapps/*.acf ${LOWERLOCATIONS[0]}/SteamLibrary/steamapps/ --remove-source-files

suro rm -rf ${UPPERLOCATIONS[1]}/Media/Games/Steam/steamapps/*

echo "Any updates to Windows Steam Library have been merged onto the NTFS partition."  | systemd-cat -t sysDSyncSteamb4Shutdown
exit 0




