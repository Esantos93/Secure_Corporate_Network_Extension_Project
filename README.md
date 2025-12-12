# Building Networked Systems Security Project: Overview

This is a project for the BNSS course (EP2520) in KTH. This repository contains some implementation scripts and code. Link to the course [here](https://www.kth.se/student/kurser/kurs/EP2520?l=en)


# Routers Configuration

## DD-WRT Firmware
Router model: Asus RT-AC68U

download firmware at: \
https://ftp.dd-wrt.com/dd-wrtv2/downloads/betas/2025/02-02-2025-r59468/asus-rt-ac68u/

1) spot router ip (ip route | grep default)
2) connect to web GUI using this IP
3) Go to Administration → Firmware Upgrade
4) upload correct firmware

brick router: 

After upgrading firmware with correct version of DD-WRT, not prompted to change credentials. Not able to access control panel so tried login/pass 3 times after stuck (ban). Tried hard reset by holding reset 30 sec, unplugging, holding 30 more sec, plugging, holding 30 more sec. Ended up in recovery mode.

## Change to Merlin-WRT

Download stock ASUS firmware at\
https://www.asus.com/networking-iot-servers/wifi-routers/asus-wifi-routers/rtac68u/helpdesk_bios/?model2Name=RTAC68U

Download Merlin-wrt firmware at\
https://sourceforge.net/projects/asuswrt-merlin/files/RT-AC68U/Release/

In theory, we could upload the stock firmware using the WEB GUI, though it seems like DD-WRT prevents itself from being overwritten, so we might have to flash the stock firmware from recovery mode\

In recovery mode (necessary mode to flash new firmware apparently), DHCP is disabled, so we have to disable it on our local computer and then set a static IPv4 address 192.168.1.X


Unplugg WAN cable !!!!!!

- Put router into recovery mode (turn it on while pressing the reset button)
- use tftp or the mini ASUS Web server to flash the asus stock firmware
- Wait for 10 min (time to flash the new firmware)
- reboot the router / or hard reset with WPS button
- new web interface should be availbale at http://192.168.1.1
- Go to Administration > upgrade firmware and upload Merlin-wrt

## debrick router:

install restoration tool at:\
https://www.asus.com/networking-iot-servers/wifi-routers/asus-wifi-routers/rtac68u/helpdesk_download/?model2Name=RTAC68U

try to upload the firmware through the tool. If router flashes red and blue on WAN / Power, likely to have "router not in Rescue mode". In that case, download new stock firmware at:\
https://www.asus.com/networking-iot-servers/wifi-routers/asus-wifi-routers/rtac68u/helpdesk_bios/?model2Name=RTAC68U

Might need to set a static IP on windows to use the following (follow instructions at https://www.asus.com/support/faq/1030642/)

Using tftp:\
tftp -i 192.168.1.1 put RT-AC68U_3.0.0.4_386_51722-g6b920b0.trx

Wait for 10 min. Then power off/on the router. LED should be blue again.
Connect to 192.168.1.1 should work


## Add ssh key to router and connect

Go to web interface to add the ssh key (have to find an automated way)

ssh -i ~/.ssh/bnss root@192.168.11.1



# DDNS setup

We used duckdns.org to provide dynamic DNS service. Under Setup > DDNS, put the duckdns token and the domain name. Chose DuckDNS and check "Use External IP Check"

# VPN tunnel setup (OpenVPN)

## GUI

Generate keys and certificate for both sides using easy-rsa:\
<code>git clone https://github.com/OpenVPN/easy-rsa.git\
cd easy-rsa/easyrsa3\
./easyrsa init-pki\
cp vars.examples vars\
./easyrsa build-ca nopass\
./easyrsa gen-req g6-server nopass\
./easyrsa sign-req server g6-server\
./easyrsa gen-req g6-client nopass\
./easyrsa sign-req client g6-client</code>


then copy paste files on the server GUI\
**Enable "use ECDH instead of DH.PEM" in the VPN pane**\
Administration > commands: \
<code>iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o $(get_wanface) -j MASQUERADE </code>\
save firewall\
Additional config: add <code>verb 5</code>

TLS: None

Add this static route to server's additional config:\
<code>route 192.168.6.0 255.255.255.0 vpn_gateway</code>

## Automation

Create an ssh key named **bnss** and place is under ~/.ssh:\
<code>cd ~/.ssh\
ssh-keygen -t ed25519
</code>\
Import this key to the router.
In the **vpn_tunnel_setup** folder, run <code>generate_certs.sh</code>. \
Connect to Stockholm, then run\
<code>bash deploy_stockholm_ovpn.sh</code>

connect to London, then run\
<code>bash deploy_london_ovpn.sh</code>

wait for the routers to reboot. The VPN tunnel is now set up.


## OpenVPN client-server setup


### Pull docker image and configure OpenVPN
<code>docker pull kylemanna/openvpn\
mkdir -p openvpn-data\
docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://130.237.11.52\
docker run -v openvpn-data:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki\
docker run -v ~/openvpn-data:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn</code>


### Forwarding rules

<code>iptables -I FORWARD -p udp -d 192.168.10.1 --dport 1194 -j ACCEPT \
iptables -t nat -A PREROUTING -p udp --dport 1194 -j DNAT --to-destination 192.168.10.X:1194</code>

Replace X with the static IP of the VPN server.


### Generate VPN Client Profiles

Each client must have a different OpenVPN configuration file containing its private key and certificate.

<code>docker run -v ~/openvpn-data:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass \
docker run -v ~/openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient CLIENTNAME > ./CLIENTNAME.ovpn
</code>

Set up DNS manually (add the following line to the OpenVPN client configuration file):\
<code>dhcp-option DNS 192.168.10.56</code>

### Connect to OpenVPN

<code>sudo openvpn --config CLIENTNAME.ovpn </code>


### Automating OpenVPN setup


sudo apt update\
sudo apt install ansible

1) enable ssh management on the router
2) run deploy_vpn.sh: <code>bash deploy_vpn.sh</code> 


### Install OpenVPN app for android

- go to play store
- search for OpenVPN for android
- open the app, click the + button, name the VPN and import client file
- You should receive an IP in the range 192.168.255.0/24

# IDS & SIEM

## Intrusion Detection System

As IDS our group has decided to use Snort3. In order to check on the traffic running on both branches, 2 instances of Snort3 will be running in parallel. Port Mirroring has been implented on the router via iptables (-TEE) and ebtables. With the port mirroring implemented, Snort is able to get a copy of every packet going through the network, from both external and internal sources to the LAN. The rules set used by Snort is based on the public set Light SPD. Via scripting this ruleset has been filtered to only apply rules whose objective is the DNS and DoS-attacks detection. For further implementation details see the [Final Report](https://github.com/cseas002/BNSS_Project/blob/main/Final%20Report.pdf). 


## Security Information and Event Management

As SIEM tool we have used Splunk. For further implementation details see the [Final Report](https://github.com/cseas002/BNSS_Project/blob/main/Final%20Report.pdf). 


# SYN Flood DoS simulation

<code>sudo hping3 192.168.10.1 -p 80 -S --flood</code>\
add --rand-source to simulate DDoS.

