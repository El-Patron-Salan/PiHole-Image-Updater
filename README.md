<h3 align="center">PiHole Updater</h3>
<h3></h3>
<p align="center">PiHole Updater updates Docker image of pihole based on the sha256 hash that's in the manifest file</p>
<p align="center">If hashes match, the script removes the current image, pulls the new one , and restarts docker-compose</p>
<h3></h3>

## Installation

Clone this repo
```
https://github.com/El-Patron-Salan/PiHole-updater.git
```
Set up crontab, by first entering to crontab config file
```
crontab -e
```
Then choose editor, schedule option ([cheatsheet](https://crontab.guru/examples.html)), and specify path to script
```
0 */12 * * * /bin/bash ~/path_to_script/PiHole_updater.sh
```
