#!/bin/bash

# Tonton Jo - 2023
# Join me on Youtube: https://www.youtube.com/c/tontonjo

# Usage:
# put script where you want it to be executed
# chmod +x /path/to/cpu_scale.sh
# Edit crontab to run script at every reboot ->
# @reboot  bash "/path/to/cpu_scale.sh" >/dev/null 2>&1"
# Reboot
# Test :)

# Version 1.0: Proof of concept
# Version 1.1: Loop is better than cron, will run everytime the script end
# Version 1.2: Use sar to get accurate average cpu load value
# Version 1.3: ensure the gouvernor is available

# --------------------- Settings ------------------------------------
averageloadupscaletime=3					# time to get average CPU load value in order to upscale
averageloaddownscaletime=10					# time to get average CPU load value in order to downscale

lowloadgouvernor=powersave		# CPU Scheduler to use when low usage
loweep=balance_power			# default performance balance_performance balance_power power
upscalevalue=25					# At wich usage when LOW load gouvernor is set the CPU will upscale to high load

highloadgouvernor=performance		# CPU Scheduler to use when low usage
higheep=performance			# default performance balance_performance balance_power power
downscalevalue=15				# At wich usage when HIGH load gouvernor is set the CPU will downscale to low load
# --------------------- Settings -------------------------------------
# ------------------- Env Variables ----------------------------------
execdir=$(dirname $0)
date=$(date +%Y_%m_%d-%H_%M_%S)
# ------------------- Env Variables ----------------------------------
if [ $(dpkg-query -W -f='${Status}' sysstat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
	apt-get install -y sysstat;
fi

# Ensuring needed gouvernors are available
if cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors | grep -qi $lowloadgouvernor; then
		if cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors | grep -qi $highloadgouvernor; then
		echo "$date - Starting Script" >> $execdir/cpu_scale.log
	else 
		echo "$date - Missing CPU Gouvernor $highloadgouvernor - check in logs for the list of availables ones on your system" >> $execdir/cpu_scale.log
  		echo "$date - Available gouvernors:" >> $execdir/cpu_scale.log
		cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors >> $execdir/cpu_scale.log
		sleep 5
		exit
	fi
else 
	echo "$date - Missing CPU Gouvernor $lowloadgouvernor - check in logs for the list of availables ones on your system"  >> $execdir/cpu_scale.log
   	echo "$date - Available gouvernors:" >> $execdir/cpu_scale.log
	cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors >> $execdir/cpu_scale.log
	sleep 5
	exit
fi

while true; do 
# --------------------- loop Variables ------------------------------------
actualgouvernor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
actualeep=$(cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference)
date=$(date +%Y_%m_%d-%H_%M_%S)
# --------------------- loop Variables ------------------------------------
# In order to not rank up or down too fast, define the average value to use
if echo "$actualgouvernor" | grep -Eqi "$lowloadgouvernor"; then
	cpuload=$(echo "$[100-$(sar -u 1 $averageloadupscaletime | awk '/^Average:/ { printf(" %.0f\n", $8)}')]")
else	
	cpuload=$(echo "$[100-$(sar -u 1 $averageloaddownscaletime | awk '/^Average:/ { printf(" %.0f\n", $8)}')]")
fi

# If the actual gouvernor is the low load gouvernor, check if CPU load is above upscale value
if echo "$actualgouvernor" | grep -Eqi "$lowloadgouvernor"; then
	if (( $(echo "$cpuload > $upscalevalue"))); then
		echo "$date - Upscaling CPU power to $highloadgouvernor at $upscalevalue% CPU load" >> $execdir/cpu_scale.log
		echo "$highloadgouvernor" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  		# echo "$higheep" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference # Cannot set EEP in Performance gouvernor
    	elif ! echo "$actualeep" | grep -Eqi "$loweep"; then
     		echo "$date - Set EEP to $loweep as it is different than it should be" >> $execdir/cpu_scale.log
     		echo "$loweep" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
	fi
# If the actual gouvernor is the high load gouvernor, check if value is under downscale value
elif echo "$actualgouvernor" | grep -Eqi "$highloadgouvernor"; then
	if (( $(echo "$cpuload < $downscalevalue"))) ; then
		echo "$date - Downscaling CPU power to $lowloadgouvernor at $downscalevalue% CPU load" >> $execdir/cpu_scale.log
		echo "$lowloadgouvernor" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  		echo "$loweep" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
	fi
# If none of the above, define the low load CPU Gouvernor
else 
	echo "$date - auto set low load gouvernor" >> $execdir/cpu_scale.log
	echo "$lowloadgouvernor" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
 	echo "$loweep" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
fi

done
