#Dummy Script for testing

source ./SteamOverlaySync.env

sudo umount /mnt/SSDWin
sudo umount /mnt/SSD2Win

sleep 1

driveLow="/mnt/winOverlay/SSDWinLower/Media/Games/Steam/steamapps"
driveTop="/mnt/winOverlay/SSDWinUpper/Media/Games/Steam/steamapps"

#makedirectories if they do not exist
sudo mkdir -p ${driveLow}/common/
sudo mkdir -p ${driveTop}/common/

sudo mkdir -p ${driveLow}/workshop/
sudo mkdir -p ${driveTop}/workshop/

sudo mkdir -p ${driveLow}/temp/
sudo mkdir -p ${driveTop}/temp

sudo mkdir -p ${driveLow}/downloads/
sudo mkdir -p ${driveTop}/downloads/

sudo mkdir -p ${driveLow}/sourcemods/
sudo mkdir -p ${driveTop}/sourcemods/



sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/common/ -u ${driveTop}/common/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/workshop/ -u ${driveTop}/workshop/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/temp/ -u ${driveTop}/temp/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/downloads/ -u ${driveTop}/downloads/  -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/sourcemods/ -u ${driveTop}/sourcemods/  -f

sudo rsync -avr ${driveTop}/*.acf ${driveLow}/

sudo rm -rf ${driveTop}/*




driveLow="/mnt/winOverlay/SSD2WinLower/SteamLibrary/steamapps/"
driveTop="/mnt/winOverlay/SSD2WinUpper/SteamLibrary/steamapps"


#makedirectories if they do not exist
sudo mkdir -p ${driveLow}/common/
sudo mkdir -p ${driveTop}/common/

sudo mkdir -p ${driveLow}/workshop/
sudo mkdir -p ${driveTop}/workshop/

sudo mkdir -p ${driveLow}/temp/
sudo mkdir -p ${driveTop}/temp

sudo mkdir -p ${driveLow}/downloads/
sudo mkdir -p ${driveTop}/downloads/

sudo mkdir -p ${driveLow}/sourcemods/
sudo mkdir -p ${driveTop}/sourcemods/



sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/common/ -u ${driveTop}/common/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/workshop/ -u ${driveTop}/workshop/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/temp/ -u ${driveTop}/temp/ -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/downloads/ -u ${driveTop}/downloads/  -f
sudo $OVERLAYTOOLSLOCATION/overlay merge -l ${driveLow}/sourcemods/ -u ${driveTop}/sourcemods/  -f

sudo rsync -avr ${driveTop}/*.acf ${driveLow}/

sudo rm -rf ${driveTop}/*



sleep 10

sudo mount -a && sudo systemctl daemon-reload