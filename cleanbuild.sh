#!/bin/sh
#
# Some commands to execute before generating the ISO to clean and purge
# the system.
#
# Last update: 2011.05.22
#

set -e

# Variable
tmp="/tmp/tmp_matriux_clean-distro"
total=3 # aptitude (update|clean|autoclean)
i=1

# C'est parti mon kiki !
(
	# Calculating ...
	[ -f ${tmp} ] && rm ${tmp}_rm
	touch ${tmp}_rm
	find / -ignore_readdir_race -type f -name "*~" | sed "s/\ /\\\ /g" >>${tmp}_rm
	find \
		/home/matriux/.cache/* \
		/home/matriux/.recently-used*  \
		/home/matriux/.thumbnails/*  \
		/root/.recently-used*  \
		/root/.thumbnails/*  \
		-ignore_readdir_race 2>/dev/null | sed "s/\ /\\\ /g" >>${tmp}_rm
	total=$( echo "${total} + $(cat ${tmp}_rm | wc -l)" | bc )
	[ -f ${tmp} ] && rm ${tmp}_pu
	touch ${tmp}_pu
	for tool in $(dpkg -l | grep '^rc' | cut -d " " -f3); do echo ${tool} >>${tmp}_pu; done
	total=$( echo "${total} + $(cat ${tmp}_pu | wc -l)" | bc )
	
	# Purging ...
	for file in $(cat ${tmp}_rm); do
		rm -rf "${file}"
		echo "${i} * 100 / ${total}" | bc
		i=$( echo "${i} + 1" | bc )
	done
	rm -f ${tmp}_rm
	sleep 1
	for package in $(cat ${tmp}_pu); do
		echo "${i} * 100 / ${total}" | bc
		aptitude -y purge ${package} >/dev/null
		i=$( echo "${i} + 1" | bc )
	done
	rm -f ${tmp}_pu
	sleep 1
	for action in update clean autoclean; do
		echo "${i} * 100 / ${total}" | bc
		aptitude ${action} >/dev/null
		sleep 1
		i=$( echo "${i} + 1" | bc )
	done
) | zenity --progress \
	--width=400 \
	--auto-close \
	--window-icon="/pt/matriux/icons/48x48/icon.png" \
	--title="Matriux - Clean up the distro" \
	--text="Working ..." \
	--percentage=0
case $? in
	-1) zenity --error --window-icon="/pt/matriux/icons/48x48/icon.png" --text="Cleaning process failed." ;;
	0)  zenity --info --window-icon="/pt/matriux/icons/48x48/icon.png" --text="Cleaning process finished." ;;
	1)  zenity --error --window-icon="/pt/matriux/icons/48x48/icon.png" --text="Cleaning process aborted." ;;
esac
exit 0
