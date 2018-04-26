#!/bin/bash
SAMBA_VERSION="4.8.1"
URL="https://download.samba.org/pub/samba/stable"
URL="http://172.16.2.2"
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
iface ${Inf[0]} inet static
address 10.$Suffix.0.10
netmask 255.255.255.0
gateway 10.$Suffix.0.254
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

echo "dc01" > /etc/hostname

cat << EOF > /etc/hosts
127.0.0.1 localhost
10.$Suffix.0.10 dc01.dominio${Suffix}.lan dc01
EOF

apt-get install acl attr autoconf bind9utils bison build-essential \
	  debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
	    libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
	      libcap-dev libcups2-dev libgnutls28-dev libgpgme11-dev libjson-perl \
	        libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl \
		  libpopt-dev libreadline-dev nettle-dev perl perl-modules pkg-config \
		    python-all-dev python-crypto python-dbg python-dev python-dnspython \
		      python3-dnspython python-gpgme python3-gpgme python-markdown python3-markdown \
		        python3-dev xsltproc zlib1g-dev bind9 -y 

if ! ls /usr/src/samba-${SAMBA_VERSION}.tar.gz 
then
	cd /usr/src/
	wget $URL/samba-${SAMBA_VERSION}.tar.gz
	tar -xf samba-${SAMBA_VERSION}.tar.gz
fi

if ! ls /usr/local/samba/sbin/samba
then
	cd /usr/src/samba-${SAMBA_VERSION}
	./configure
	make
	make install
	echo "export PATH=\$PATH:/usr/local/samba/sbin:/usr/local/samba/bin" > /etc/profile.d/samba4.sh
	chmod +x /etc/profile.d/samba4.sh
fi
reboot
