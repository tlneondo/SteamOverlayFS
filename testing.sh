#Dummy Script for testing

source ./SteamOverlaySync.env



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
