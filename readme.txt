This attempt uses a systemd file to run the script after user processes have been shut down, but before drives are unmounted, thus ensuring nothing will make the drives busy.

server file needs to be copied to systemd directory and enabled


run "SteamOverlaySync.sh manual" to run the program now