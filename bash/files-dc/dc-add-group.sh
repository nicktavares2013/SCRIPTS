#!/bin/bash
GroupOU="ou=Grupos"
DbFILE="/usr/local/samba/private/sam.ldb"
Domain="dc=dominio8,dc=lan"
SAMDOM="dominio8"

if [ -z $1 ]
then
	echo "$0 <nome do grupo>"
else
	GE=`ldbsearch -H $DbFILE -b $GroupOU,$Domain cn=$1 | egrep ^cn | wc -l`
	if [ $GE -ne 1 ]
	then
		LastGID=`ldbsearch -H $DbFILE -b $GroupOU,$Domain  gidnumber | egrep gid | awk '{ print $ 2 }' | sort -n | tail -1`
		NextGID=$((${LastGID}+1))
		samba-tool group add $1 --groupou=$GroupOU --nis-domain=$SAMDOM --gid-number=${NextGID}
	else
		echo "$1 já existe"
	fi
fi
