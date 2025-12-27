source ../config/SyncConfig.env
source ./copyfunction.env
source ./drivemounting.env
source ./systemfunctions.env


cleanupOldScripts

killPeskyProcesses


#mask systemd mounting
sudo systemctl mask systemd-remount-fs.service

#unmount overlays
for ((i=0; i < lengthOver; i++ )); do
    unmountFinalOverlays "${OVERFSLOCATIONS[$i]}"
done




#remount ro ntfs drives as readable
for ((i=0; i < lengthLower; i++ )); do
    remountROLowerasReadable "${LOWERLOCATIONS[$i]}"
done


#generate scripts
for ((i=0; i < lengthOver; i++ )); do

    #check disk space
    diskCheck=$(compareDiskUsage ${UPPERLOCATIONS[$i]} ${LOWERLOCATIONS[$i]})

    if ((diskCheck == 1)); then
        echo "There is enough Space in ${LOWERLOCATIONS[$i]} to proceed."
        generateScripts ${UPPERLOCATIONS[$i]} ${LOWERLOCATIONS[$i]}
    elif ((diskCheck == -1)); then
        echo "Not enough Space in ${LOWERLOCATIONS[$i]} to proceed."
        breakOutExit
    fi

done


sudo chown $USER:$USER ./overlay-tools*.sh


#remove any linux related folders from scripts
processScripts

#run scripts
for file in overlay-tools*.sh; do
    sudo bash ./$file
    #sudo bash ./$file.remove.sh
    sync
    sync
done

#delete all in UPPERLOCATIONS
for ((i=0; i < lengthUpper; i++ )); do
    deleteUppers ${UPPERLOCATIONS[$i]}
done

#hide certain folders in upper overlay 

hideFolderinOverlay

sleep 5

#run function as part of exit
breakOutExit

