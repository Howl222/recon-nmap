# recon-nmap
### Description

The recon script performs port scanning of all ports quickly and efficiently. It can also scan UDP and TCP ports for IPv6 and identifies vulnerabilities with nmap. 

The fuzz script is used for automated fuzzing on http servers with the most common options already implemented. 

- - -

### Install:

**Kali:**
                   
```
sudo apt -y install seclists
sudo apt install ffuf
```
                   
**Other Linux:**
                   
```
sudo git clone https://github.com/danielmiessler/SecLists /usr/share/seclists
sudo apt install nmap
sudo apt install ffuf
sudo apt-get install -y whatweb 
```

### Recon Usage:
```
recon.sh [Options] [IP]
       -u          UDP Scan
       -6          TCP Scan by IPv6
       -v          Vuln Scan
       -B          Basic TCP Scan (Default)
       -C          Scan by TCP and UDP
       -A          Scan by TCP, UDP and vuln Scan
```
### Fuzz Usage:
```
fuzz.sh [Options] [IP/DIR]
       -e          Extensions (Ex: php,html,txt)
       -o          Output File (Default: webScan)
       -w          Wordlist (Default: directory-list-2.3-medium)
       -s          Subdomains (Default wordlist: subdomains-top1million-110000.txt)
       -n          Don't follow redirect
       -a          Hide words (Default: 0, Only with subdomain enumeration)
       -c          Hide code (Default: 404)
```






