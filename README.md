# recon-nmap
### Description

The recon script performs port scanning of all ports quickly and efficiently. It can also scan UDP and TCP ports for IPv6 and identifies vulnerabilities with nmap.\ 

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

Usage:
```
recon.sh [Options] [IP]<
       -u          UDP Scan
       -6          TCP Scan by IPv6
       -v          Vuln Scan
       -B          Basic TCP Scan (Default)
       -C          Scan by TCP and UDP
       -A          Scan by TCP, UDP and vuln Scan
```



