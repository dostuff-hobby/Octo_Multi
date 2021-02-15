#!/bin/bash

for i in octoprint1 octoprint2 octoprint3
do
	systemctl stop $i
done

userdel -r octouser1
userdel -r octouser2
userdel -r octouser3
groupdel octoprinter
rm -rf /usr/local/User_Apps
rm -r /etc/init.d/octo*
rm -r /etc/default/octo*
ps -ef | grep octo | grep -v "shared_install_octoprint" | awk '{print $2}' | xargs kill -9

reset
clear
