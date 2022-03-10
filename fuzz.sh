#!/bin/bash

function ctrlC(){
	echo -e "\n\n[!]Saliendo...\n"
	rm "extensions.txt" &>/dev/null
	exit 1
}

trap ctrlC INT


function help(){

	echo -e "\n[+]Usage: $0 [Options] [IP/DIR]\n"
	echo -e "\t\t-e \t\t\tExtensions (Ex: php,html,txt)"
	echo -e "\t\t-o \t\t\tOutput File"
	echo -e "\t\t-w \t\t\tWordlist (Default: directory-list-2.3-medium)"
	echo -e "\t\t-s \t\t\tSubdomains (Default wordlist: subdomains-top1million-110000.txt)"
	echo -e "\t\t-n \t\t\tDon't follow redirect"
	echo -e "\t\t-a \t\t\tHide words (Default: 0, Only with subdomain enumeration)"
	echo -e "\t\t-c \t\t\tHide code (Default: 404)"
	exit 0
}


if [[ $# -eq 0  ]]; then
	help
fi

output="webScan"
wordlist="/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
hideWords="0"
hideCode="404"

while getopts ":e:o:a:w:c:" arg
do
    case $arg in
        e) extensions=${OPTARG};;
		o) output=${OPTARG};;
		w) wordlist=${OPTARG};;
		a) hideWords=${OPTARG};;
		c) hideCode=${OPTARG};;
    esac
done

url=""
subdomain=""
redirect="-L"

while [[ -n $1 ]]; do
	
	if [[ "$1" == "-s"  ]]; then
		subdomain="True"
	elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
		help
	elif [[ "$1" == "-n" ]]; then
		redirect=""
	fi

	url="$1"
	shift
done

if [[ "$subdomain" == "True"  ]]; then
	if [[ $wordlist == "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt" ]]; then
		wordlist="/usr/share/secLists/Discovery/DNS/subdomains-top1million-110000.txt"
	fi
	wfuzz -c -t 200 "--hc=$hideCode" "--hw=$hideWords" -L -f "subdomainScan" -w  "$wordlist" -H "Host:FUZZ.$url"  "http://$url/"
elif [[ "$extensions" == ""  ]]; then
	wfuzz -c -t 200 "--hc=$hideCode" "$redirect"  -f "$output" -w  "$wordlist" "http://$url/FUZZ"
else
	echo "$extensions" |  tr "," '\n' > "extensions.txt"
	wfuzz -c -t 200 "--hc=$hideCode" "$redirect"  -f "extensions$output" -w  "$wordlist" -w "extensions.txt" "http://$url/FUZZ.FUZ2Z"
	rm "extensions.txt" &>/dev/null
fi

