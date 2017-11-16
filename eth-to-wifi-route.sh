#!/bin/bash

# Share Eth with WiFi Hotspot
#
# This script is created to work with Raspbian Stretch
# but it can be used with most of the distributions
# by making few changes. 
#
# Make sure you have already installed `dnsmasq` and `hostapd`
# Please modify the variables according to your need
# Don't forget to change the name of network interface
# Check them with `ifconfig`

ip_address="192.168.2.1"
netmask="255.255.255.0"
dhcp_range_start="192.168.2.2"
dhcp_range_end="192.168.2.100"
dhcp_time="12h"
eth="enp4s0"
wlan="wlp2s0"
ssid="Arpit-Raspberry"
psk="arpit1997"

sudo rfkill unblock wlan &> /dev/null
sleep 2

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE  
sudo iptables -A FORWARD -i $eth -o $wlan -m state --state RELATED,ESTABLISHED -j ACCEPT  
sudo iptables -A FORWARD -i $wlan -o $eth -j ACCEPT 

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

sudo ifconfig $wlan $ip_address netmask $netmask

sudo ip route del 0/0 dev $wlan &> /dev/null
a=`route | awk "/${eth}/"'{print $5+1;exit}'`
sudo route add -net default gw $ip_address netmask 0.0.0.0 dev $wlan metric $a

echo -e "interface=$wlan \n\
bind-interfaces \n\
server=8.8.8.8 \n\
domain-needed \n\
bogus-priv \n\
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /etc/dnsmasq.conf

sudo systemctl restart dnsmasq

echo -e "interface=$wlan\n\
driver=nl80211\n\
ssid=$ssid\n\
hw_mode=g\n\
ieee80211n=1\n\
wmm_enabled=1\n\
macaddr_acl=0\n\
auth_algs=1\n\
ignore_broadcast_ssid=0\n\
wpa=2\n\
wpa_key_mgmt=WPA-PSK\n\
wpa_passphrase=$psk\n\
rsn_pairwise=CCMP" > /etc/hostapd/hostapd.conf

sudo systemctl restart hostapd
sudo systemctl status hostapd &> /dev/null
if [ "$?" != 0 ];then
	echo "Some Network Management tool is running, which is stopping" 
	echo "hostapd to be configured."
	echo "Please stop that and again run the script."
fi
