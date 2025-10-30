source ./SyncConfig.env
source ./copyfunction.env
source ./drivemounting.env
source ./SteamACFtracking.env

sudo systemctl mask systemd-remount-fs.service


lengthOver=${#OVERFSLOCATIONS[*]}

#unmount overlays

for ((i=0; i < lengthOver; i++ )); do
    unmountFinalOverlays "${OVERFSLOCATIONS[$i]}"
done


length=${#UPPERLOCATIONS[*]}
lengthOver=${#OVERFSLOCATIONS[*]}
lengthLower=${#LOWERLOCATIONS[*]}

#remount ro ntfs drives as readable



for ((i=0; i < lengthLower; i++ )); do
    echo ${i}
    echo ${LOWERLOCATIONS[$i]}
    remountROLowerasReadable "${LOWERLOCATIONS[$i]}"
done



#unmask lower locations
sudo systemctl unmask   systemd-remount-fs.service
for ((k=0; k < lengthLower; k++ )); do
    sudo systemctl --runtime unmask "$(systemd-escape -p --suffix=automount ${LOWERLOCATIONS[$k]})"
done


#unmask service
sudo systemctl unmask systemd-remount-fs.service

#unmask final overlays
sudo systemctl unmask   systemd-remount-fs.service
for ((k=0; k < lengthOver; k++ )); do
    sudo systemctl --runtime unmask "$(systemd-escape -p --suffix=automount ${OVERFSLOCATIONS[$k]})"
done



sync
sync
sudo mount -a && sudo systemctl daemon-reload && sudo systemctl restart local-fs.target
sync
sync