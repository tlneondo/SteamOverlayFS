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

sync

for ((k=0; k < lengthOver; k++ )); do
    sudo systemctl --runtime mask "$(systemd-escape -p --suffix=automount ${OVERFSLOCATIONS[$k]})"
    sudo umount ${OVERFSLOCATIONS[$k]}
done

sleep 5

length=${#UPPERLOCATIONS[*]}

for ((i=0; i < length; i++ )); do
    copyFiles ${UPPERLOCATIONS[$i]} ${LOWERLOCATIONS[$i]}
done


sudo chown $USER:$USER ./overlay-tools*.sh


#remove any linux related folders from scripts
for file in overlay-tools*.sh; do
sed -i '/steamapps\/compatdata/d' ./$file
sed -i '/steamapps\/shadercache/d' ./$file
sed -i '/steamapps\/temp/d' ./$file

#split into remove and copy scripts
grep 'rm' ./$file > ./$file.remove.sh
sed -i 'rm/d' ./$file
done

#run scripts
for file in overlay-tools*.sh; do
    sudo bash ./$file
    sudo bash ./$file.remove.sh
done

#delete all in UPPERLOCATIONS
#for ((i=0; i < length; i++ )); do
#    deleteUppers ${UPPERLOCATIONS[$i]}
#done

sleep 5


#unmask
sudo systemctl unmask  systemd-remount-fs.service
for ((k=0; k < lengthOver; k++ )); do
    sudo systemctl --runtime unmask "$(systemd-escape -p --suffix=automount ${OVERFSLOCATIONS[$k]})"
done


sudo mount -a && sudo systemctl daemon-reload && sudo systemctl restart local-fs.target
