#!/bin/bash

function ctrlC(){
	
	echo "[!]Exit the program? (Default No)"
	
	read -r line
	if [[ -n $line  ]]; then
		echo -e "\n\n[!]Exit...\n"
		exitFunc 1
	fi
	return 0 
}

function exitFunc(){
	rm "$tmpFile" "$tmpFile2" &>/dev/null
	tput cnorm
	exit "$1"
}

trap ctrlC INT
tput civis

function help(){

	echo -e "\n[+]Usage: $0 [Options] [IP/DIR]\n"
	echo -e "\t\t-e  [Extensions]\t\tExtensions (Ex: php,html,txt)"
	echo -e "\t\t-o  [Output]\t\t\tOutput File"
	echo -e "\t\t-w  [Wordlist]\t\t\tWordlist (Default: directory-list-2.3-medium)"
	echo -e "\t\t-n \t\t\t\tDon't follow redirect"
	echo -e "\t\t-c  [Code]\t\t\tHide code "
	echo -e "\t\t-hw [Words]\t\t\tHide Words"
	echo -e "\t\t-l \t\t\t\tHttps mode"
	echo -e "\t\t-s \t\t\t\tSubdomains enumeration(Default wordlist: subdomains-top1million-110000.txt)"
	echo -e "\t\t-a \t\t\t\tAuto calibrate (Default: True) Only for subdomain enumeration"
	echo -e "\t\t-z [Options]\t\t\tExtra options for Ffuf"
	exitFunc 0
}

function createOutputFile(){

	touch "$output" 
	cat "$1" >> "$output"
	return 0
}

function writeOutputFile(){

	local results resultsStatus numTabs aux tabs dir

	dir="$2"
	results=()  
	resultsStatus=()

	while IFS='' read -r line; do results+=("$line"); done < <(jq '.results[].input.FUZZ' "$tmpFile" | tr -d '"') 
	while IFS='' read -r line; do resultsStatus+=("$line"); done < <(jq '.results[].status' "$tmpFile" | tr -d '"') 

	aux=$(echo "$url" | awk -F "/" '{print $(NF)}')
	numTabs=$(echo "$url" | grep -o '/' | wc -l)

	for (( i=0 ; i < $(echo "${results[@]}" | wc -w) ; i++ )) ; do
		
        if [[ ${results[$i]} == "" ]]; then
            continue
        fi
        {
		echo -n "$dir${results[$i]}" 
		n=$(echo -n "$dir${results[$i]}" | wc -c)
		for (( j=0; j < (80-n-numTabs*4); j++)); do
		 	echo -n " "
		done 
		echo "${resultsStatus[$i]}" 
		} >> "$tmpFile2"
	done

	if [[ ! -e "$tmpFile2" ]]; then
		return 0
	fi

	if $1 ; then
		echo -e "Subdomains: $url\n" > "$output"
		cat "$tmpFile2" >> "$output"
		return 0
	fi

	if [[ ! -e $output ]]; then
	    createOutputFile "$tmpFile2"
	  	return 0  
    else
		cat "$tmpFile2" >> "$output"
		sort -u "$output" | sponge "$output"
	fi

	return 0
}


if [[ $# -eq 0  ]]; then
	help
fi

url=""
output=""
wordlist="/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
hideCode=""
hideWords=""
subdomain=false
redirect="-r"
autoCalibrate="-ac"
extraOptions=""
tmpFile="tmpFile.txt" #/tmp/tmpFile.txt
tmpFile2="tmpFile2.txt" # New directories and files discovered
req="http"

while [[ -n $1 ]]; do
	
	if [[ "$1" == "-h" || "$1" == "--help"  ]]; then
		help
	elif [[ "$1" == "-s" ]]; then
		subdomain=true
	elif [[ "$1" == "-e" ]]; then
		extensions="$2"
	elif [[ "$1" == "-o" ]]; then
		output="$2"
	elif [[ "$1" == "-hw" ]]; then
		hideWords="-fw $2"
	elif [[ "$1" == "-w" ]]; then
		wordlist="$2"
	elif [[ "$1" == "-c" ]]; then
		hideCode="-fc $2"
	elif [[ "$1" == "-n" ]]; then
		redirect=""
	elif [[ "$1" == "-a" ]]; then
		autoCalibrate=""
	elif [[ "$1" == "-l" ]]; then
		req="https"
	elif [[ "$1" == "-z" ]]; then
		extraOptions="$2"
	fi

	url="$1"
	shift
done

if [[ -z "$output" ]]; then
	output="$url""WebScan.txt"
fi


url=$(echo "$url" | sed 's/\/\//\//g')

if $subdomain ; then
	if [[ $wordlist == "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt" ]]; then
		wordlist="/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
	fi
	ffuf -c -t 200 -o $tmpFile $hideWords $hideCode $extraOptions $autoCalibrate -w $wordlist -u "$req://$url/" -H "Host: FUZZ.$url"
	error=$?
	output="subdomainEnumeration.txt"
	writeOutputFile true
elif [[ -z "$extensions" ]]; then
	ffuf -c -t 200 -o $tmpFile  -w "$wordlist" $redirect $hideWords $hideCode $extraOptions -u "$req://$url/FUZZ"
	error=$?
	writeOutputFile false "$req://$url/"
else
	extensions=$( echo "$extensions" | tr ',' '\n' | ts '.' | tr -d ' ' | tr '\n' ',' )
	unset extensions[${#extensions[@]}]
	ffuf -c -t 200 -o $tmpFile  -w "$wordlist" $redirect -e "$extensions" $hideWords $hideCode $extraOptions -u "$req://$url/FUZZ"
	error=$?
	writeOutputFile false
fi

if [[ "$error" != "0" ]]; then
	echo -e "\n\n[-]An error has occurred"
fi

exitFunc 0 
