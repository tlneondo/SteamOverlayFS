#Dummy Script for testing

source ./SyncConfig.env
source ./copyfunction.env
source ./drivemounting.env
source ./SteamACFtracking.env

#unmount overlays
for i in ${UPPERLOCATIONS[$i]}
do
    echo "Unmounting $i" | systemd-cat -t sysDSyncSteamb4Shutdown
    if mountpoint -q "$i"; then
        sudo umount "$i"
        if [[ $? -ne 0 ]]; then
            echo "Failed to unmount $i, exiting" | systemd-cat -t sysDSyncSteamb4Shutdown
            exit 1
        fi
    else
        echo "$i is not mounted, skipping unmount" | systemd-cat -t sysDSyncSteamb4Shutdown
    fi
done


sleep 1


for y in ${UPPERLOCATIONS[@]}
do
    copyFiles ${UPPERLOCATIONS[@]} ${LOWERLOCATIONS[@]}
done


sleep 10

reloadFromFSTAB()

