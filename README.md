# recon-nmap
### Description

The recon script performs port scanning of all ports quickly and efficiently. It can also scan UDP and TCP ports for IPv6 and identifies vulnerabilities with nmap. 

The fuzz script is used for automated fuzzing on http servers with the most common options already implemented. 

- - -

### Install:

**Kali:**
                   
```
apt -y install seclists
pip install wfuzz
```
                   
**Other Linux:**
                   
```
git clone https://github.com/danielmiessler/SecLists /usr/share/seclists
pip install wfuzz
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
### To do:

**recon.sh:**

- [ ] Implement function fuzzing with http open ports
- [ ] Recon OS with icmp
- [ ] Create a file with open ports and services for taking notes (notes.txt)
- [ ] Execute nikto with all http ports in background
- [ ] Execute whatweb with all http ports 
    
**fuzz.sh**

- [ ] Option -a for all options
- [ ] Create one file with the webpage structure, that file updates the content  





