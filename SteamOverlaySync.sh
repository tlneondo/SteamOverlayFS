#!/usr/bin/pkexec /bin/bash 

echo "Script Start: Merge OverlayFS into NTFS Drive" | systemd-cat -t sysDSyncSteamb4Shutdown

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo or pkexec. Exiting." | systemd-cat -t sysDSyncSteamb4Shutdown
   exit 200
fi


SCRIPT_RUN_TYPE=0
#1 = manual, 2 = at shutdown

#check args
if [[ $# -ne 0 ]]; then
    echo "No arguments expected, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 99
fi

if [[ "$1" == "manual" || "$1" == "--manual" || "$1" == "-m" ]]; then
    echo "Running Steam Sync Manually" | systemd-cat -t sysDSyncSteamb4Shutdown
    SCRIPT_RUN_TYPE=1
fi

if [[ "$1" == "atshutdown" || "$1" == "--atshutdown" || "$1" == "-as" ]]; then
    echo "Running Steam Sync At Shutdown" | systemd-cat -t sysDSyncSteamb4Shutdown
    SCRIPT_RUN_TYPE=2
fi

if [[ $SCRIPT_RUN_TYPE -eq 0 ]]; then
    echo "No valid arguments provided, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 100
fi

# Get the directory of the current script and set the overlay location
SCRIPT_DIR="$(dirname "$0")"
CONFIGLOCATION="$HOME/.config/SteamOverlaySync/"

#load configuration file

if [[ "$OVERRIDE_CONFIG_FILE" -eq 1 ]]; then
    echo "Loading non-default config file" | systemd-cat -t sysDSyncSteamb4Shutdown
    if [[ -f "$SCRIPT_DIR/OtherConfig.env" ]]; then
        source "$SCRIPT_DIR/OtherConfig.env"
    else
        echo "Configuration file not found at $SCRIPT_DIR/OtherConfig.env, exiting." | systemd-cat -t sysDSyncSteamb4Shutdown
        exit 300
    fi
else
    if [[ -f "$CONFIGLOCATION/SteamOverlaySync.env" ]]; then
        source "$CONFIGLOCATION/SteamOverlaySync.env"
    else
        echo "Configuration file not found at $CONFIGLOCATION/SteamOverlaySync.env, exiting." | systemd-cat -t sysDSyncSteamb4Shutdown
        exit 300
    fi
fi


#check that length of arrays are equal
if [[ ${#UPPERLOCATIONS[@]} -ne ${#LOWERLOCATIONS[@]} ]] || [[ ${#UPPERLOCATIONS[@]} -ne ${#MERGELOCATIONS[@]} ]]; then
    echo "Error: UPPERLOCATIONS, LOWERLOCATIONS, and MERGELOCATIONS arrays must have the same length." | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 350
fi

#check drive space in all layers


for i in "${!UPPERLOCATIONS[@]}"; do

    echo "Checking disk space for ${UPPERLOCATIONS[$i]} and ${LOWERLOCATIONS[$i]}" | systemd-cat -t sysDSyncSteamb4Shutdown


    #check if disk space in layer is less than free space on drive
    amtinLayer=$(du -c -d 0 ${UPPERLOCATIONS[$i]} | grep "total" | awk '{printf "%s",$1}')
    amtFreeOnDrive=$(df --total | grep "${LOWERLOCATIONS[$i]}" | awk '{printf "%s",$4}')

    printf "Amount in layer: %s\n" "$amtinLayer" | systemd-cat -t sysDSyncSteamb4Shutdown
    printf "Amount free on drive: %s\n" "$amtFreeOnDrive" | systemd-cat -t sysDSyncSteamb4Shutdown

    if [[ $amtinLayer -gt $amtFreeOnDrive ]]
    then
        echo "Failing Merging %s into %s\n" "${UPPERLOCATIONS[$i]}" "${LOWERLOCATIONS[$i]}" | systemd-cat -t sysDSyncSteamb4Shutdown
        echo "Not enough space on drive to merge changes, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
        exit 22
    fi

done


function copyFiles(){
    local params=("$@")
    driveTop=${params[0]}
    driveLow=${params[1]}


    echo "use overlayfs tools to merge changes from ${driveTop} to ${driveLow}"  | systemd-cat -t sysDSyncSteamb4Shutdown

    sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/Media/Games/Steam/steamapps/common/ -u ${driveTop}/Media/Games/Steam/steamapps/common/ -f
    sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/Media/Games/Steam/steamapps/workshop/ -u ${driveTop}/Media/Games/Steam/steamapps/workshop/ -f
    sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/Media/Games/Steam/steamapps/temp/ -u ${driveTop}/Media/Games/Steam/steamapps/temp/ -f
    sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/Media/Games/Steam/steamapps/downloads/ -u ${driveTop}/Media/Games/Steam/steamapps/downloads/ -f
    sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/Media/Games/Steam/steamapps/sourcemods/ -u ${driveTop}/Media/Games/Steam/steamapps/sourcemods/ -f

    sudo rsync -avr ${driveTop}/Media/Games/Steam/steamapps/*.acf ${driveLow}/Media/Games/Steam/steamapps/ --remove-source-files

    suro rm -rf ${driveTop}/Media/Games/Steam/steamapps/*
}

function unmountFinalOverlays(){
    local params=("$@")
    finalMountPoints=${params[0]}

    echo "Unmounting final mount poitns" | systemd-cat -t sysDSyncSteamb4Shutdown

    for mountPoint in "${finalMountPoints[@]}"; do
        if mountpoint -q "$mountPoint"; then
            sudo umount "$mountPoint"
            if [[ $? -ne 0 ]]; then
                echo "Failed to unmount $mountPoint, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
                exit 1
            fi
        else
            echo "$mountPoint is not mounted, skipping unmount" | systemd-cat -t sysDSyncSteamb4Shutdown
        fi
    done
}

function remountReadOnlyFS(){
    local params=("$@")
    ntfsROLocations=${params[0]}
    UUIDS=${params[1]}

    echo "Unmounting RO NTFS mount POINTS" | systemd-cat -t sysDSyncSteamb4Shutdown

    for mountPoint in "${ntfsROLocations[@]}"; do
        if mountpoint -q "$mountPoint"; then
            sudo umount "$mountPoint"
            if [[ $? -ne 0 ]]; then
                echo "Failed to unmount $mountPoint, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
                exit 1
            fi
        else
            echo "$mountPoint is not mounted, skipping unmount" | systemd-cat -t sysDSyncSteamb4Shutdown
        fi
    done
}

unmountFinalOverlays "${OVERFSLOCATIONS[@]}"
remountReadOnlyFS "${LOWERLOCATIONS[@]}" "${UUIDLIST[@]}"

sleep 1

#loop through the upper layers and merge them into the lower layers
for i in "${!UPPERLOCATIONS[@]}"; do
    echo "Merging changes from ${UPPERLOCATIONS[$i]} into ${LOWERLOCATIONS[$i]}" | systemd-cat -t sysDSyncSteamb4Shutdown
    copyFiles "${UPPERLOCATIONS[$i]}" "${LOWERLOCATIONS[$i]}"
done
echo "Any updates to Windows Steam Library have been merged onto the NTFS partition."  | systemd-cat -t sysDSyncSteamb4Shutdown


if(SCRIPT_RUN_TYPE -eq 0); then
    echo "Readying for System Shutdown" | systemd-cat -t sysDSyncSteamb4Shutdown
    exit 0
fi

if(SCRIPT_RUN_TYPE -eq 1); then
    echo "Remounting Drives" | systemd-cat -t sysDSyncSteamb4Shutdown
    sudo mount -a
    if [[ $? -ne 0 ]]; then
        echo "Failed to remount drives, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
        exit 1
    fi
fi







