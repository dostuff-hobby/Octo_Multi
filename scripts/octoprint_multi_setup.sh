#!/bin/bash

root_check () {
	if [ ${UID} != 0 ]; then
		echo -e "\nThis script should be run as root or with sudo privileges"
		return 1
		exit 1
	else
		return 0
fi
}
root_check

export install_dir=/usr/local/User_Apps/Octoprint

dependency_check () {
	echo -e "\nChecking for and Installing python3-pip and python3-venv"
	chkpy3pip=`dpkg-query -l | grep python3-pip | grep "^ii"`
	chkpy3venv=`dpkg-query -l | grep python3-venv | grep "^ii"`
	if [ -z "$chkpy3pip" ]; then
		/usr/bin/apt-get -y update
		/usr/bin/apt-get -y install python3-pip
		if [ -z "$chkpy3venv" ]; then
			/usr/bin/apt-get -y install python3-venv
		fi
	fi
	return 0
}
dependency_check

user_setup () {
	echo -e "\ncreating octoprint group"
	groupadd octoprinter
	
	echo -e "\n\n"
	#read -p "How many octoprint servers do you want?[1]:" OCTOCOUNT
	read -p "`echo  -e "\033[32;5mHow many octoprint servers do you want?[1]:\033[0m"`" OCTOCOUNT
	OCTOCOUNT=${OCTOCOUNT:-1}
	
	for i in $(seq 1 "$OCTOCOUNT")
	do
		useradd octouser$i -d /home/octouser$i -m -s /bin/bash -g octoprinter
		usermod -a -G dialout octouser$i
		echo octouser$i:octouser$i | chpasswd
	done
return 0
}
user_setup

stage_install_dir () {
	if [ ! -d $install_dir ]; then
		mkdir -p $install_dir
		chgrp octoprinter $install_dir
		chmod -R g+w $install_dir
	fi
	return 0
}
stage_install_dir

venv_setup () {
	su octouser1 <<'EOF'
		python3 -m venv $install_dir
		source $install_dir/bin/activate
		pip install pip --upgrade
		pip install octoprint
EOF
		return 0
}
venv_setup

set_init_script () {

	echo "#!/bin/sh

### BEGIN INIT INFO
# Provides:          octoprint
# Required-Start:    \$local_fs networking
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: OctoPrint daemon
# Description:       Starts the OctoPrint daemon with the user specified in
#                    /etc/default/octoprint.
### END INIT INFO

# Author: Sami Olmari & Gina Häußge

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC=\"OctoPrint Daemon\"
NAME=\"OctoPrint\"
PKGNAME=octoprint
PIDFILE=/var/run/\$PKGNAME.pid
SCRIPTNAME=/etc/init.d/\$PKGNAME
DEFAULTS=/etc/default/\$PKGNAME

# Read configuration variable file if it is present
[ -r \$DEFAULTS ] && . \$DEFAULTS

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

# Exit if the DAEMON is not set
if [ -z \"\$DAEMON\" ]
then
    log_warning_msg \"Not starting \$PKGNAME, DAEMON not set in /etc/default/\$PKGNAME.\"
    exit 0
fi

# Exit if the DAEMON is not installed
[ -x \"\$DAEMON\" ] || exit 0

# Load the VERBOSE setting and other rcS variables
[ -f /etc/default/rcS ] && . /etc/default/rcS

if [ -z \"\$START\" -o \"\$START\" != \"yes\" ]
then
   log_warning_msg \"Not starting \$PKGNAME, edit /etc/default/\$PKGNAME to start it.\"
   exit 0
fi

if [ -z \"\$OCTOPRINT_USER\" ]
then
    log_warning_msg \"Not starting \$PKGNAME, OCTOPRINT_USER not set in /etc/default/\$PKGNAME.\"
    exit 0
fi

COMMAND_ARGS=
if [ -n \"\$BASEDIR\" ]
then
    COMMAND_ARGS=\"--basedir \$BASEDIR \$COMMAND_ARGS\"
fi

if [ -n \"\$CONFIGFILE\" ]
then
    COMMAND_ARGS=\"--config \$CONFIGFILE \$COMMAND_ARGS\"
fi

#
# Function to verify if a pid is alive
#
is_alive()
{
   pid=\`cat \$1\` > /dev/null 2>&1
   kill -0 \$pid > /dev/null 2>&1
   return \$?
}

#
# Function that starts the daemon/service
#
do_start()
{
   # Return
   #   0 if daemon has been started
   #   1 if daemon was already running
   #   2 if daemon could not be started

   is_alive \$PIDFILE
   RETVAL=\"\$?\"

   if [ \$RETVAL != 0 ]; then
       start-stop-daemon --start --background --quiet --pidfile \$PIDFILE --make-pidfile \
       --exec \$DAEMON --chuid \$OCTOPRINT_USER --user \$OCTOPRINT_USER --umask \$UMASK --nicelevel=\$NICELEVEL \
       -- serve \$COMMAND_ARGS \$DAEMON_ARGS
       RETVAL=\"\$?\"
   fi
}

#
# Function that stops the daemon/service
#
do_stop()
{
   # Return
   #   0 if daemon has been stopped
   #   1 if daemon was already stopped
   #   2 if daemon could not be stopped
   #   other if a failure occurred

   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user \$OCTOPRINT_USER --pidfile \$PIDFILE
   RETVAL=\"\$?\"
   [ \"\$RETVAL\" = \"2\" ] && return 2

   rm -f \$PIDFILE

   [ \"\$RETVAL\" = \"0\"  ] && return 0 || return 1
}

case \"\$1\" in
  start)
   [ \"\$VERBOSE\" != no ] && log_daemon_msg \"Starting \$DESC\" \"\$NAME\"
   do_start
   case \"\$?\" in
      0|1) [ \"\$VERBOSE\" != no ] && log_end_msg 0 ;;
      2) [ \"\$VERBOSE\" != no ] && log_end_msg 1 ;;
   esac
   ;;
  stop)
   [ \"\$VERBOSE\" != no ] && log_daemon_msg \"Stopping \$DESC\" \"\$NAME\"
   do_stop
   case \"\$?\" in
      0|1) [ \"\$VERBOSE\" != no ] && log_end_msg 0 ;;
      2) [ \"\$VERBOSE\" != no ] && log_end_msg 1 ;;
   esac
   ;;
  status)
   status_of_proc -p \$PIDFILE \$DAEMON \$NAME && exit 0 || exit \$?
   ;;
  restart)
   log_daemon_msg \"Restarting \$DESC\" \"\$NAME\"
   do_stop
   case \"\$?\" in
     0|1)
      do_start
      case \"\$?\" in
         0) log_end_msg 0 ;;
         1) log_end_msg 1 ;; # Old process is still running
         *) log_end_msg 1 ;; # Failed to start
      esac
      ;;
     *)
        # Failed to stop
      log_end_msg 1
      ;;
   esac
   ;;
  *)
   echo \"Usage: \$SCRIPTNAME {start|stop|status|restart}\" >&2
   exit 3
   ;;
esac" > /etc/init.d/octoprint_template

	for i in $(seq 1 "$OCTOCOUNT")
	do
		if [ -e /etc/init.d/octoprint_template ]; then
			cp /etc/init.d/octoprint_template /etc/init.d/octoprint$i
			chmod +x /etc/init.d/octoprint$i
		fi

		sed -i -e "s/DESC=\"OctoPrint Daemon\"/DESC=\"Octoprint$i Daemon\"/" /etc/init.d/octoprint$i
		sed -i -e "s/NAME=\"OctoPrint\"/NAME=\"OctoPrint$i\"/" /etc/init.d/octoprint$i
		sed -i -e "s/PKGNAME=octoprint/PKGNAME=octoprint$i/" /etc/init.d/octoprint$i

		echo -e "# Configuration for /etc/init.d/octoprint$i\n# The init.d script will only run if this variable non-empty.\nOCTOPRINT_USER=octouser$i\n\n# base directory to use\n#BASEDIR=/home/pi/.octoprint\n\n# configuration file to use\n#CONFIGFILE=/home/pi/.octoprint/config.yaml\n\n# On what port to run daemon, default is 5000\nPORT=500$i\n\n# Path to the OctoPrint executable, you need to set this to match your installation!\n#DAEMON=/home/pi/OctoPrint/venv/bin/octoprint\nDAEMON=$install_dir/bin/octoprint\n\n# What arguments to pass to octoprint, usually no need to touch this\nDAEMON_ARGS="--port=\$PORT"\n\n# Umask of files octoprint generates, Change this to 000 if running octoprint as its own, separate user\nUMASK=022\n\n# Process priority, 0 here will result in a priority 20 process.\n# -2 ensures Octoprint has a slight priority over user processes.\nNICELEVEL=-2\n\n# Should we run at startup?\nSTART=yes" > /etc/default/octoprint$i
	done
	return 0
}
set_init_script

get_plugins () {
	echo -e "\n\n"
	#read -p "Do you want to install plugins? [N]" PLUGINS
	read -p "`echo  -e "\033[32;5mDo you want to install plugins? [N]\033[0m"`" PLUGINS
	if echo "$PLUGINS" | grep -iq "^y" ; then
		su octouser1 <<'EOF'
		source $install_dir/bin/activate
		pip install "https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip"
		pip install "https://github.com/OllisGit/OctoPrint-DisplayLayerProgress/releases/latest/download/master.zip"
		pip install "https://github.com/dattas/OctoPrint-DetailedProgress/archive/master.zip"
		pip install "https://github.com/cesarvandevelde/OctoPrint-M73Progress/archive/master.zip"
		pip install "https://github.com/OctoPrint/OctoPrint-FirmwareUpdater/archive/master.zip"
		pip install "https://github.com/FormerLurker/Octolapse/archive/v0.3.4.zip"
		pip install "https://github.com/jneilliii/OctoPrint-CustomBackground/archive/master.zip"
		pip install "https://github.com/kantlivelong/OctoPrint-GCodeSystemCommands/archive/master.zip"
		pip install "https://github.com/jneilliii/OctoPrint-BLTouch/archive/master.zip"
		pip install "https://github.com/imrahil/OctoPrint-NavbarTemp/archive/master.zip"
		pip install "https://github.com/pablogventura/Octoprint-ETA/archive/master.zip"
		pip install "https://github.com/google/OctoPrint-HeaterTimeout/archive/master.zip"
		pip install "https://github.com/Salandora/OctoPrint-FileManager/archive/master.zip"
		pip install "https://github.com/BillyBlaze/OctoPrint-TouchUI/archive/master.zip"
		pip install "https://github.com/fabianonline/OctoPrint-Telegram/archive/stable.zip"
		pip install "https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip"
		pip install "https://github.com/tjjfvi/OctoPrint-IFTTT/archive/master.zip"
		pip install "https://github.com/amsbr/OctoPrint-Stats/archive/master.zip"
EOF
	fi
	return 0
}
get_plugins

chmod -R g+w $install_dir/*

enable_daemon () {
	echo -e "\n\n"
	#read -p "Do you want to enable octoprint servers to start on boot? [N]: " AUTOSTARTER
	read -p "`echo  -e "\033[32;5mDo you want to enable octoprint servers to start on boot? [N]:\033[0m"`" AUTOSTARTER
	if echo "$AUTOSTARTER" | grep -iq "^y" ;then
		if [ ! -z `which systemctl` ]; then
			for i in $(seq 1 "$OCTOCOUNT")
			do
				systemctl enable octoprint$i
			done
		else
			if [ ! -z `which chkconfig` ]; then
				for i in $(seq 1 "$OCTOCOUNT")
				do
					chkconfig octoprint$i on
				done
			fi
		fi
	fi
	return 0
}
enable_daemon

start_daemon () {
	echo -e "\n\n"
	#read -p "Do you want to start the daemons now? [N]: " STARTME
	read -p "`echo  -e "\033[32;5mDo you want to start the daemons now? [N]:\033[0m"`" STARTME
	if echo "$STARTME" | grep -iq "^y" ;then
		if [ ! -z `which systemctl` ]; then
			for i in $(seq 1 "$OCTOCOUNT")
			do
				systemctl start octoprint$i
			done
		else
			if [ ! -z `which chkconfig` ]; then
				for i in $(seq 1 "$OCTOCOUNT")
				do
					service octoprint$i start
				done
			fi
		fi
	fi
	return 0
}
start_daemon

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

echo -e "\n\n\nOctoprint has been configured for the following users:\n`for i in $(seq 1 "$OCTOCOUNT") ;do echo -e "octouser$i in /home/octouser$i";done`\n\nOctoprint has been installed to $install_dir/bin/octoprint"
