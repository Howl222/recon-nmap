#!/bin/bash


function ctrlC(){
	echo -e "\n\n[-]Exit..."
	exitCode 1
	exit 1
}

trap ctrlC SIGINT
tput civis

function exitCode(){
	rm "allPorts.txt" "allPortsUDP.txt" &>/dev/null
	tput cnorm
	exit "$1"
}

function help(){
	echo -e "\n[*]Usage: $0 [Options] [IP]"
	echo -e "\t\t-u \t\tUDP Scan"
	echo -e "\t\t-6 \t\tTCP Scan by IPv6"
	echo -e "\t\t-v \t\tVuln Scan"
	echo -e "\t\t-B \t\tBasic TCP Scan (Default)"
	echo -e "\t\t-C \t\tScan by TCP and UDP"
	echo -e "\t\t-A \t\tScan by TCP, UDP and vuln Scan"
	exitCode 0
}

function scanTCP(){
	
	echo -e "\n[*]Starting Scanning TCP Ports\n"

	if $1 ; then
		nmap -sS -p- --open --min-rate 5000 -n -Pn -6 "$ip" -oG "allPorts.txt" &> /dev/null
	else
		nmap -sS -p- --open --min-rate 5000 -n -Pn "$ip" -oG "allPorts.txt" &> /dev/null
	fi

    ports=$(grep -oP '\d{1,5}/open' "allPorts.txt" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

	echo -e "[+]Open Ports: $ports\n"

	echo -e "[+]Scanning Services:\n"

	if $1 ; then
		nmap -sC -sV "-p$ports" -6 "$ip" -Pn -oN "targetedIPv6.txt" &> /dev/null
		grep -v "# Nmap" "targetedIPv6.txt"
	else
		nmap -sC -sV "-p$ports" "$ip" -Pn -oN "targeted.txt" &> /dev/null
		grep -v "# Nmap" "targeted.txt"
	fi

	echo -e "\n[*]End of TCP Scan\n"
}


function scanUDP(){

	echo -e "\n[*]Starting Scanning UDP Ports\n"
	nmap -sU --top-ports 10000 --min-rate 5000 "$ip" -oG "allPortsUDP.txt" &> /dev/null

    local ports
	ports=$(grep -oP '\d{1,5}/open' "allPortsUDP.txt" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

	echo -e "[+]Open Ports: $ports\n"

	echo -e "[+]Scanning Services:\n"

	nmap -sU -sC -sV "-p$ports" "$ip" -Pn -oN "targetedUDP.txt" &> /dev/null

	echo -e "\n[*]End of UDP Scan\n"

}

function vulnScan(){



	if [[ -z "$ports" ]]; then
		echo -e "[-]You have to do a scan for tcp"
		scanTCP false
	fi

	echo -e "\n[*]Starting Vuln Scan\n"

	nmap "-p$ports" --script "vuln and safe" "$ip" -Pn -oN "vulnScan.txt"
}

function fuzzing(){
	fuzz -w "/usr/share/seclists/Discovery/Web-Content/common.txt" -o "webScanCommon.txt" "$1"
}

function osDiscovery(){

	echo -e "\n[*]OS Discovery:\n"

	ttl=$(ping -c 1 "$ip" | grep "ttl" | cut -d " " -f6 | cut -d '=' -f2)

	if (( "$ttl" >= 0 && "$ttl" <= 64 )); then
		echo -e "[+] The server is Linux"
	elif (( "$ttl" >= 65 && "$ttl" <= 128 )); then
		echo -e "[+] The server is Windows"
	else
		echo -e "[-] Unknown OS"
	fi
}

function httpScan(){

	local httpPorts 
	
	httpPorts=$(grep http targeted.txt | grep -oP '\d{1,5}/tcp' | awk -F '/' '{print $1}')

	cont=$(echo "$httpPorts" | tr '\n' ',' | grep -o "," | wc -l)

	if (( "$cont" == 0 )); then
		return 0
	fi

	echo -e "[*]HTTP Scan\n"

	for (( i = 1 ; i <= "$cont"; i++ )) ; do
		port=$(echo "$httpPorts" | tr '\n' ',' | awk -F ',' "{print \$$i}")
		whatweb "$ip:$port"
		echo
	done | tee "whatwebScan.txt"
	echo 
	for (( i = 1 ; i <= "$cont"; i++ )) ; do
		port=$(echo "$httpPorts" | tr '\n' ',' | awk -F ',' "{print \$$i}")
		fuzzing "$ip:$port"
	done

	rm "nikto.txt" &>/dev/null
	nikto -h "$ip" -port "$(echo "$httpPorts" | tr '\n' ',')" | tee "nikto.txt" &>/dev/null  &

	return 0
}

function basicTCPScan(){

	osDiscovery

	scanTCP false 

	httpScan

	return 0
}

function completeScan(){

	osDiscovery

	scanTCP false 

	httpScan

	scanUDP

	return 0
}

function scanAll(){

	osDiscovery

	scanTCP false 

	httpScan

	scanUDP

	vulnScan

	return 0
}

if (( $# == 0 && $# <= "3" ));then
	help
fi

if [[ "$#" == 1 && "$1" != "-h" && "$1" != "--help" ]]; then
	ip=$1
	basicTCPScan
	exitCode 0
fi

doUdpScan=false
ipv6Scan=false
doVulnScan=false
doBasicTCPScan=false
doCompleteScan=false
doScanAll=false

while [[ -n $1 ]]; do
	
	if [[ "$1" == "-u"  ]]; then
		doUdpScan=true
	elif [[ "$1" == "-6" ]]; then
		ipv6Scan=true
	elif [[ "$1" == "-v" ]]; then
		doVulnScan=true
	elif [[ "$1" == "-B" ]]; then
		doBasicTCPScan=true
	elif [[ "$1" == "-C" ]]; then
		doCompleteScan=true
	elif [[ "$1" == "-A" ]]; then
		doScanAll=true
	elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
		help
	fi

    ip="$1"
	shift
done

if $doBasicTCPScan ; then
	basicTCPScan false
fi

if $doCompleteScan ; then
	completeScan
fi

if $doScanAll ; then
	scanAll
fi


if $ipv6Scan ; then
	scanTCP true
fi

if $doUdpScan ; then
	scanUDP
fi

if $doVulnScan ; then
	vulnScan
fi

echo -e "\n[+]End of Scan"

exitCode 0



