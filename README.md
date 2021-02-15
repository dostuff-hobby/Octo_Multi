# Octo_Multi
Custom script to setup mulitple Octoprint instances on a single Pi using python virtual environment and pip to install Octoprint and the plugins.

This script was written in my spare time and presently has only been tested on Ubuntu 20.04 and Rasbian 10 and thus is only presently supporting a Debian-based or apt based package manager workflow.

This script is intended to be run only one time and for a fresh configuration, the error checking isn't phenominal so multiple executions are likely to present errors.

The script contains a block of common plugins that I use personally that you may disable or modify to suit your needs.

The clean.sh script is a quick and dirty cleanup script which will erase all configurations setup by the octoprint_multi_setup.sh script minus the removal of the python3-pip and python3-venv packages installed with apt.

I personally use a set of custom udev rules to identify each printer I own and operate with Octoprint so that each printer has a persistent device name in /dev/ which allows me to easily statically bind each Octoprint instance to a given printer - while I do this all manually today, I'm not entirely sure how I may be able to help automate or facilitate this type of configuration nor am I certain that I can provide an easy to follow writeup for non-technical individuals to utilize.
You will find these lines commented in the octoprint_multi_setup.sh script, these were notes to myself and I may remove them at a future date but the enterprising and fearless among us may desire to try and follow them to get a similar configuration outcome.

#/etc/udev/rules.d/99-3D_Printers.rules
#SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="ttyE3"
#SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="ttyE3_Linear"
#SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="Chiron"
#SUBSYSTEM=="tty", ATTRS{idVendor}=="VENDORID", ATTRS{idProduct}=="PRODUCTID", SYMLINK+="PRINTERNAME"
#udevadm info -a -n /dev/ttyUSB1
#udevadm info -a -n /dev/ttyUSB1|grep idVendor
#udevadm info -a -n /dev/ttyUSB1|grep idProduct
#udevadm info -a -n /dev/ttyUSB1|grep bInterfaceNumbers
#udevadm info -a -n /dev/ttyUSB0|grep idVendor|grep -i devpath

#SKR 1.4 Turbo = OpenMoko, Inc.
#lsusb|grep -i "OpenMoko" | awk '{print $6}' | cut -d ":" -f 2
