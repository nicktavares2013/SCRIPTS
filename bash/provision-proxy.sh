#!/bin/bash
Suffix=$1
InfFILE="/etc/network/interfaces"
Inf=( `ip -4 l | egrep enp[0-9]s[0-9] -o `)


if [ -z $1 ]
then
	echo "$0 <sua posicao>"
        exit -1
else
	if [ $Suffix -gt 15 ]
	then 
		echo "$0 <0-15>"
		exit -1
	fi	
fi
cat << EOF > $InfFILE
auto lo ${Inf[0]} ${Inf[1]}
iface lo inet loopback
iface ${Inf[0]} inet dhcp
iface ${Inf[1]} inet static
address 10.$Suffix.0.254
netmask 255.255.255.0
EOF
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem	sftp	/usr/lib/openssh/sftp-server
EOF

echo "proxy" > /etc/hostname

cat << EOF > /etc/hosts
127.0.0.1 localhost
127.1.1.1 proxy.dominio${Suffix}.lan proxy
EOF

if ! dpkg -L squid3
then
	apt-get install squid3 -y
fi

if ! dpkg -L bind9 
then 
	apt-get install bind9 -y
fi

squid3 -k shutdown
squid3 -k shutdown
squid3 -k shutdown
squid3 -k shutdown
sleep 5

mkdir -p /var/cache/proxy

squid -z

chown proxy.proxy /var/cache/proxy
chmod 2770 /var/cache/proxy

mkdir -p /srv/proxy/rules.d /srv/dns/zones
chmod 2770 /srv/proxy/rules.d
chmod 2770 /srv/dns/zones
chown proxy.proxy -R /srv/proxy
chown bind.bind -R /srv/dns

cat << EOF > /srv/proxy/rules.d/sites-liberados.acl
.gov.br
.org
.edu
EOF

cat << EOF > /srv/proxy/rules.d/sites-bloqueados.acl
.uol.br
.terra.br
.globo.br
EOF

cat << EOF > /etc/squid/squid.conf
visible_hostname proxy
dns_nameservers 127.0.0.1
http_port 3128
coredump_dir /var/spool/squid
cache_dir ufs /var/cache/proxy 100 16 256

acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
acl CONNECT method CONNECT
acl Debian dstdomain .debian.org
acl SitesAllow dstdomain "/srv/proxy/rules.d/sites-liberados.acl"
acl SitesDeny dstdomain "/srv/proxy/rules.d/sites-bloqueados.acl"

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localhost
http_access allow Debian
http_access allow SitesAllow
http_access deny SitesDeny
http_access deny all



refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
EOF
service squid start

cat << EOF > /etc/bind/named.conf.options
options {
	directory "/var/cache/bind";
	forwarders {
	 	208.67.222.222;
		8.8.8.8;
	};
	dnssec-validation auto;
	auth-nxdomain no;    # conform to RFC1035
	listen-on { any; };
};
EOF

service bind9 restart
reboot
