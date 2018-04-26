#!/bin/bash
userOU="ou=Usuarios"
groupOU="ou=Grupos"
DbFILE="/usr/local/samba/private/sam.ldb"
Domain="dc=dominio8,dc=lan"
SAMDOM="dominio8"
NetLOGON="/srv/dc01.dominio8.lan/netlogon"

if [ $# -lt 2 ]
then
	echo "$0 <nome do usuario> <nome do grupo>"
else
	GE=`ldbsearch -H $DbFILE -b $userOU,$Domain cn=$1 | egrep ^cn | wc -l`
	if [ $GE -ne 1 ]
	then
		GidNUMBER=`ldbsearch -H $DbFILE -b $groupOU,$Domain  cn=$2 gidnumber | egrep ^gid | awk '{ print $ 2 }'`
		if [ -z $GidNUMBER ]
		then
			GidNUMBER=5001
		fi
		LastUID=`ldbsearch -H $DbFILE -b $userOU,$Domain  uidnumber | egrep -i uidnum | awk '{ print $ 2 }' | sort -n | tail -1`
		if [ -z $LastUID ]
		then
			LastUID=5000
		fi
		NextUID=$((${LastUID}+1))
		samba-tool user create $1 --userou=$userOU --nis-domain=$SAMDOM --gid-number=$GidNUMBER --script-path=$NetLOGON/$1.bat --home-drive=U --home-directory=/home/`echo $1 | cut -c 1`/$1 --nis-domain=$SAMDOM --unix-home=/home/`echo $1 | cut -c 1`/$1 --uid=$1 --uid-number=$NextUID --login-shell=/bin/bash --random-password
			
		GRUPO=`ldbsearch -H $DbFILE -b $groupOU,$Domain gidnumber=$GidNUMBER cn | egrep ^cn | awk '{ print $ 2 }'`
		samba-tool group addmembers $GRUPO $1
		samba-tool user setpassword $1 --newpassword=P@ssw0rd
		mkdir -p /home/`echo $1 | cut -c 1`/$1 
		chmod 770 /home/`echo $1 | cut -c 1`/$1
		chown $1 /home/`echo $1 | cut -c 1`/$1
		echo -e "@echo off\nnet use w: \\dc01\dados\n" > $NetLOGON/$1.bat
		chmod +x $NetLOGON/$1.bat
	
	else
		echo "$1 já existe"
	fi
fi
