#!/bin/bash


function ctrlC(){
	echo -e "\n\n[-]Exit..."
	exit 1
}

trap ctrlC SIGINT

function help(){
	echo -e "\n[*]Usage: $0 [IP]"
	echo -e "\t\t-u \t\tUDP Scan"
	echo -e "\t\t-6 \t\tTCP Scan by IPv6"
	echo -e "\t\t-v \t\tVuln Scan"
	echo -e "\t\t-B \t\tBasic TCP Scan (Default)"
	echo -e "\t\t-C \t\tScan by TCP and UDP"
	echo -e "\t\t-A \t\tScan by TCP, UDP and vuln Scan"
	exit 0
}

function scanTCP(){
	
	if $1 ; then
		nmap -sS -p- --open --min-rate 5000 -n -Pn -6 "$ip" -oG "allPorts.txt" &> /dev/null
	else
		nmap -sS -p- --open --min-rate 5000 -n -Pn "$ip" -oG "allPorts.txt" &> /dev/null
	fi

	local ports
    ports=$(grep -oP '\d{1,5}/open' "allPorts.txt" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

	echo -e "\n[+]Open Ports: $ports\n"

	if [[ "$ports" =~ "80" && $1 = false ]]; then
		whatweb "$ip" 2>/dev/null
	fi


	echo -e "\n[+]Scanning Services:\n"

	if $1 ; then
		nmap -sC -sV "-p$ports" -6 "$ip" -Pn -oN "targetedIPv6" &> /dev/null
	else
		nmap -sC -sV "-p$ports" "$ip" -Pn -oN "targeted" &> /dev/null
	fi
}


function scanUDP(){
	nmap -sU --top-ports 10000 --min-rate 1000 "$ip" -oG "allPortsUDP.txt" &> /dev/null

    local ports
	ports=$(grep -oP '\d{1,5}/open' "allPortsUDP.txt" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

	echo -e "\n[+]Open Ports: $ports\n"

	echo -e "\n[+]Scanning Services:\n"

	nmap -sU -sC -sV "-p$ports" "$ip" -Pn -oN "targetedUDP" &> /dev/null
}

function vulnScan(){

	nmap "-p$ports" --script "vuln and safe" "$ip" -Pn -oN vulnScan
}

function fuzzing(){
	fuzz -w "/home/kali/Diccionarios/common.txt" -o "webScanCommon.txt"
}

function basicTCPScan(){

	echo -e "\n[*]Starting Scanning TCP Ports"
	scanTCP false
	return 0
}

function completeScan(){

	echo -e "\n[*]Starting Scanning TCP Ports"

	scanTCP

	echo -e "\n[*]Starting Scanning UDP Ports"

	scanUDP

	return 0
}

function scanAll(){
	echo -e "\n[*]Starting Scanning TCP Ports"

	scanTCP

	echo -e "\n[*]Starting Scanning UDP Ports"

	scanUDP

	echo -e "\n[*]Starting Vuln Scan"

	vulnScan

	return 0
}


if (( $# == 0 && $# <= "3" ));then
	help
fi

if [[ "$#" == 1 && "$1" != "-h" && "$1" != "--help" ]]; then
ip=$1
	basicTCPScan
fi

udpScan=false
ipv6Scan=false
vulnScan=false

while [[ -n $1 ]]; do
	
	if [[ "$1" == "-u"  ]]; then
		udpScan=true
	elif [[ "$1" == "-6" ]]; then
		ipv6Scan=true
	elif [[ "$1" == "-v" ]]; then
		vulnScan=true
	elif [[ "$1" == "-B" ]]; then
		basicTCPScan
	elif [[ "$1" == "-C" ]]; then
		completeScan
	elif [[ "$1" == "-A" ]]; then
		scanAll
	elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
		help
	fi

    ip="$1"
	shift
done

if $udpScan ; then
	udpScan
fi

if $ipv6Scan ; then
	scanTCP true
fi

if $vulnScan ; then
	vulnScan
fi

echo -e "\n[+]End of Scan"

rm "allPorts.txt" "allPortsUDP.txt" &>/dev/null




