source ./SyncConfig.env
source ./copyfunction.env
source ./drivemounting.env
source ./SteamACFtracking.env

sudo rm ./overlay-tools*.sh

killall steam

sleep 5

#mask systemd mounting
sudo systemctl mask systemd-remount-fs.service

lengthOver=${#OVERFSLOCATIONS[*]}

for ((i=0; i < lengthOver; i++ )); do
    unmountFinalOverlays "${OVERFSLOCATIONS[$i]}"
done

sleep 5

#prompt user if un

length=${#UPPERLOCATIONS[*]}
lengthOver=${#OVERFSLOCATIONS[*]}


#generate scripts
for ((i=0; i < length; i++ )); do
    generateScripts ${UPPERLOCATIONS[$i]} ${LOWERLOCATIONS[$i]}
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
for ((i=0; i < length; i++ )); do
    deleteUppers ${UPPERLOCATIONS[$i]}
done

sleep 5


#unmask
sudo systemctl unmask   systemd-remount-fs.service
for ((k=0; k < lengthOver; k++ )); do
    sudo systemctl --runtime unmask "$(systemd-escape -p --suffix=automount ${OVERFSLOCATIONS[$k]})"
done

sync
sync
sudo mount -a && sudo systemctl daemon-reload && sudo systemctl restart local-fs.target
sync
sync