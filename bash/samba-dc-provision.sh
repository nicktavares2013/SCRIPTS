#!/bin/bash
Suffix=$1
PASS='P4$$w0rd'

if [ -z $1 ]
then
	echo "$0 <posicao>"
	exit -1
fi

	
SAMDOM="dominio${Suffix}.lan"
DOM="dominio${Suffix}"
if ! ls /etc/systemd/system/samba-ad-dc.service
then
	cat << EOF > /etc/systemd/system/samba-ad-dc.service
[Unit]
Description=Samba Active Directory Domain Controller
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/samba/sbin/samba -D
PIDFile=/usr/local/samba/var/run/samba.pid
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl enable samba-ad-dc
fi

# Provision 
if ! ls /usr/local/samba/private/sam.tdb
then
	samba-tool domain provision --domain=${DOM} --realm $SAMDOM --use-rfc2307 --adminpass=${PASS} --dns-backend=BIND9_DLZ
	rm -f /etc/krb5.conf
	ln -sf /usr/local/samba/private/krb5.conf /etc/krb5.conf
	mkdir /etc/samba
	ln -sf /usr/local/samba/etc/smb.conf /etc/samba/smb.conf
	cat << EOF > /usr/local/samba/private/named.conf
dlz "AD DNS Zone" {
      database "dlopen /usr/local/samba/lib/bind9/dlz_bind9_10.so -d 3";
};
EOF


	cat << EOF >  /etc/bind/named.conf
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
include "/usr/local/samba/bind-dns/named.conf";
EOF

	cat << EOF > /etc/bind/named.conf.options
options {
	directory "/var/cache/bind";
	dnssec-validation auto;
	auth-nxdomain no;    # conform to RFC1035
	listen-on { any; };
	tkey-gssapi-keytab "/usr/local/samba/bind-dns/dns.keytab";
};
EOF
	service bind9 restart
	ln -sf /usr/local/samba/lib/libnss_winbind.so.2 /lib/x86_64-linux-gnu/
	ln -sf /lib/x86_64-linux-gnu/libnss_winbind.so.2 /lib/x86_64-linux-gnu/libnss_winbind.so
	ldconfig
cat << EOF > /etc/nsswitch.conf
passwd:         compat winbind
group:          compat winbind
shadow:         compat
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF

	service samba-ad-dc start
fi
