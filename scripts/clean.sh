#!/bin/bash

for i in `ls /etc/init.d/|grep octoprint|grep -v template`
do
	service $i stop
	rm -r /etc/init.d/$i
done

for i in `grep "^octouser" /etc/passwd | awk -F: '{print $1}'`
do
	userdel -r $i
done

groupdel octoprinter
rm -rf /usr/local/User_Apps
rm -r /etc/default/octo*

ps -ef | grep octo | grep -v "shared_install_octoprint" | awk '{print $2}' | xargs kill -9

reset
clear
