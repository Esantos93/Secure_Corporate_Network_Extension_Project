# BNSS_Project
This is a project in BNSS course (EP2520) in KTH, in which we have to implement network stuff. 
Our group is Sniff_my_packets_420 (Group 6). This repository contains some implementation scripts and code.

The main idea is that there are two corporate networks, one in Stockholm and one in London, and the employees from one site should be able to connect and communicate with the other site through a VPN connection (Site-to-Site), but also the employees should connect remotely (Client-to-Site)

To implement this, we used OpenVPN for both Site-to-Site and Client-to-Site connectivity.

Of course, there will be a lot more stuff here, such as web servers, file sharing servers, CA servers, damn that's a lot.


# flash router:
## DD-WRT
download firmware at: \
https://ftp.dd-wrt.com/dd-wrtv2/downloads/betas/2025/02-02-2025-r59468/asus-rt-ac68u/

1) spot router ip (ip route | grep default)
2) connect to web GUI using this IP
3) Go to Administration → Firmware Upgrade
4) upload correct firmware

brick router: 

After upgrading firmware with correct version of DD-WRT, not prompted to change credentials. Not able to access control panel so tried login/pass 3 times after stuck (ban). Tried hard reset by holding reset 30 sec, unplugging, holding 30 more sec, plugging, holding 30 more sec. Ended up in recovery mode.

# Change to Merlin-WRT

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


# Add ssh key to router and connect

Go to web interface to add the ssh key (have to find an automated way)

ssh -i ~/.ssh/bnss root@192.168.11.1



# DDNS setup



# Webserver
## build web server docker image

docker build -t nginx_web_server . \
docker stop webserver\
docker rm webserver \
docker run -d -p 80:80 --name webserver --network host nginx_web_server

Here the "--network host" option binds nginx to the systems eth0 port (it skips the docker bridge)

## Forwarding rules for the web server 

- write ansible playbook for forwarding rules
- write automation script to deploy web server with docker \
- run the deployment script \
<code>bash deploy_web_server.sh</code>


# VPN tunnel setup (OpenVPN)

## GUI
go through the 40 pages document:

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

Working setup: TLS: None

Add this static route to server's additional config:\
<code>route 192.168.6.0 255.255.255.0 vpn_gateway</code>

## Automation

Create an ssh **named bnss** and place is under ~/.ssh:\
<code>cd ~/.ssh\
ssh-keygen -t ed25519
</code>

In the **vpn_tunnel_setup** folder, run <code>generate_certs.sh</code>. Connect to Stockholm, then run\
<code>bash deploy_stockholm_ovpn.sh</code>

connect to London, then run\
<code>bash deploy_london_ovpn.sh</code>

wait for the routers to reboot. The VPN tunnel is now set up.


# OpenVPN client-server setup


## Pull docker image and configure OpenVPN

docker pull kylemanna/openvpn \
mkdir -p openvpn-data \
docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://130.237.11.52 \
docker run -v openvpn-data:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki \
docker run -v ~/openvpn-data:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn


## Forwarding rules

iptables -I FORWARD -p udp -d 192.168.10.1 --dport 1194 -j ACCEPT \
iptables -t nat -A PREROUTING -p udp --dport 1194 -j DNAT --to-destination 192.168.10.X:1194

## Generate VPN Client Profiles

Each client must have a different OpenVPN configuration file containing its private key and certificate.

docker run -v ~/openvpn-data:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass \
docker run -v ~/openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient CLIENTNAME > ./CLIENTNAME.ovpn

Set up DNS manually (add the following line to the OpenVPN client configuration file):\
<code>dhcp-option DNS 192.168.10.56</code>

## Connect to OpenVPN

<code>sudo openvpn --config CLIENTNAME.ovpn </code>


## Automating OpenVPN setup


sudo apt update
sudo apt install ansible

1) write deploy_vpn.sh
2) write ansible playbook router_config.yaml
3) enable ssh management on the router (to be automated)
4) run deploy_sh: <code>bash deploy_vpn.sh</code> 


## Install OpenVPN app for android

- go to play store
- search for OpenVPN for android
- open the app, click the + button, name the VPN and import client file
- You should receive an IP in the range 192.168.255.0/24

# Authentication server FreeIPA / FreeRadius

## setup DNS resolver to FreeIPA's one:\

under Services > Services > additional options:\
<code>
dhcp-option=6,192.168.10.56,8.8.8.8,8.8.4.4\
dhcp-option=6,192.168.10.56
</code>
## Freeradius

base DN: <code>dc=acme,dc=local</code>\
install freeradius locally
<code>sudo apt install freeradius freeradius-utils freeradius-ldap</code>

to input under ldap (sudo nano /etc/freeradius/3.0/mods-available/ldap)

        server = "192.168.10.56"
        identity = "uid=admin,cn=users,cn=accounts,dc=acme,dc=local"
        password = "IpaManager420!"
        base_dn = "cn=users,cn=accounts,dc=acme,dc=local"
        filter = "(uid=%{Stripped-User-Name})"
        start_tls = yes
        tls_require_cert = never

enabling ldap module:\
<code>sudo ln -s /etc/freeradius/3.0/mods-available/ldap /etc/freeradius/3.0/mods-enabled/
</code>    

enable ldap under authorize section of this file:\
<code>sudo nano /etc/freeradius/3.0/sites-enabled/default</code>

Uncomment the Auth-type { ldap } section under authentication section


Try Ldap connection:\
<code>ldapsearch -x -H ldap://192.168.10.56 -D "uid=admin,cn=users,cn=accounts,dc=acme,dc=local" -w 'IpaManager420!' -b "cn=users,cn=accounts,dc=acme,dc=local"</code>

Test Radius authentication:\
<code>radtest gtest caraolo 127.0.0.1 1812 testing123 </code>

Kerberos: <code>sudo apt-get install freeradius-krb5\
sudo ln -s /etc/freeradius/3.0/mods-available/krb5 /etc/freeradius/3.0/mods-enabled/
</code>

site-enabled/default --> krb5

on the FreeIPA server:\
<code>ipa-getkeytab -s freeipa.acme.local -p radius/freeradius.acme.local@ACME.LOCAL  -k /tmp/radius.keytab
</code>

Modifying EAP module: changing TLS configuration (needed for PEAP and TTLS)\
<code>
tls-config tls-common {\
        private_key_file = /etc/freeradius/certs/server.key\
        certificate_file = /etc/freeradius/certs/server.pem\
        ca_file = /etc/freeradius/certs/ca.pem\
        dh_file = /etc/freeradius/certs/dh\
        cipher_list = "DEFAULT"\
    }</code>

