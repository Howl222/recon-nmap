#!/bin/bash

function ctrlC(){
	echo -e "\n\n[!]Saliendo...\n"
	rm "extensions.txt" $tmpFile  &>/dev/null
	exit 1
}

trap ctrlC INT


function help(){

	echo -e "\n[+]Usage: $0 [Options] [IP/DIR]\n"
	echo -e "\t\t-e \t\t\tExtensions (Ex: php,html,txt)"
	echo -e "\t\t-o \t\t\tOutput File"
	echo -e "\t\t-w \t\t\tWordlist (Default: directory-list-2.3-medium)"
	echo -e "\t\t-n \t\t\tDon't follow redirect"
	echo -e "\t\t-s \t\t\tSubdomains (Default wordlist: subdomains-top1million-110000.txt)"
	echo -e "\t\t-a \t\t\tHide words (Default: 0, Only with subdomain enumeration)"
	echo -e "\t\t-c \t\t\tHide code (Default: 404)"
	exit 0
}

function createOutputFile(){

	touch "$output"
	echo -e "$url\n" >> "$output"
	echo "$1" >> "$output"
	return 0
}

function writeOutputFile () {
	local numTabs aux tabs dir newDirectories
	numTabs=$(echo "$url" | grep -o '/' | wc -l)
	aux=$(echo "$url" | awk -F "/" '{print $(NF)}')
	tabs=$(for (( i=0; i < $numTabs - 1; i++ )); do echo -n -e "\t"; done)
	dir=$tabs$aux
	newDirectories=$(awk -F '\t' '{print $4}' "$tmpFile" | grep -oP '".*?"' | tr -d '"')

	if [[ ! -e $output ]]; then
		createOutputFile "$newDirectories"
		return 0 
	fi

	if [[ "$dir" == "" ]]; then
		 echo "$newDirectories" >> "$output"
		 return 0
	fi
	while read -r line; do
		if [[ "$line" == "$dir" ]]; then
			echo -e "\n$tabs\t"
			echo "$newDirectories"
		else
			echo "$line" 
		fi
	done < "$output" >> "tmpFile.txt"
		
	rm "$output" &>/dev/null

	mv "tmpFile.txt" "$output"

	return 0 
}


if [[ $# -eq 0  ]]; then
	help
fi

url=""
output="webScan.txt"
wordlist="/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt"
hideWords="0"
hideCode="404"
subdomain=false
redirect="-L"
tmpFile="tmpFile.txt"

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



while [[ -n $1 ]]; do
	
	if [[ "$1" == "-s"  ]]; then
		subdomain=true
	elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
		help
	elif [[ "$1" == "-n" ]]; then
		redirect=""
	fi

	url="$1"
	shift
done


url=$(echo "$url" | sed 's/\/\//\//g')
#url="${url[@]:0:${#url[@]}-1}"

defaultChars=$(curl -s "http://$url/asdkjjnfdjnasfdj" | wc -c)

if $subdomain ; then
	if [[ $wordlist == "/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt" ]]; then
		wordlist="/usr/share/secLists/Discovery/DNS/subdomains-top1million-110000.txt"
	fi
	wfuzz -c -t 200 "--hw=$hideWords" -L -f "subdomainScan.txt" -w  "$wordlist" -H "Host:FUZZ.$url"  "http://$url/" 2> /dev/null
elif [[ -z "$extensions" ]]; then
	wfuzz -c -t 200 "--hc=$hideCode"  "--hh=$defaultChars" "$redirect"  -f "$tmpFile" -w  "$wordlist" "http://$url/FUZZ" 2> /dev/null
	writeOutputFile
else
	echo "$extensions" |  tr "," '\n' > "extensions.txt"
	wfuzz -c -t 200 "--hc=$hideCode" "--hh=$defaultChars" "$redirect"  -f "$tmpFile" -w  "$wordlist" -w "extensions.txt" "http://$url/FUZZ.FUZ2Z" 2> /dev/null
	rm "extensions.txt" &>/dev/null
fi

rm $tmpFile &>/dev/null

