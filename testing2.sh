source ./SyncConfig.env
source ./copyfunction.env
source ./drivemounting.env
source ./SteamACFtracking.env

sudo rm ./overlay-tools*.sh

killall steam

sleep 5

lengthOver=${#OVERFSLOCATIONS[*]}

for ((k=0; k < lengthOver; k++ )); do
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
done

#run scripts
for file in overlay-tools*.sh; do
    bash ./$file
done

#delete all in UPPERLOCATIONS
for ((i=0; i < length; i++ )); do
    deleteUppers ${UPPERLOCATIONS[$i]}
done

sleep 5

sudo mount -a && sudo systemctl daemon-reload && sudo systemctl restart local-fs.target
