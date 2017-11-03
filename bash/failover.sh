#!/bin/bash
InfDefault=eth0
InfPPP=eth1
HostMonitor=8.8.4.4
InfFile=/var/lib/failover.info
DelayCheck=10
> $InfFile
_Check_Info () {
	if [ ! -s $InfFile ]
	then 
	    dhclient -r > /dev/null 2>&1
	    ip r del default  > /dev/null 2>&1
	    dhclient $InfDefault 
	    echo "address1:`ip -4 -o a | egrep $InfDefault | awk '{ print $ 4 }'`" > $InfFile
	    echo "gateway1:`ip r | egrep default | egrep -o '(via.*dev)' | awk '{ print $ 2 }'`" >> $InfFile
	    dhclient -r $InfDefault 
	    ip r del default
	    dhclient $InfPPP
	    echo "address2:`ip -4 -o a | egrep $InfPPP | awk '{ print $ 4 }'`" >> $InfFile
	    echo "gateway2:`ip r | egrep default | egrep -o '(via.*dev)' | awk '{ print $ 2 }'`" >> $InfFile
	fi
}
_FailOver () {
	InfinUse=$( ip r | egrep default |  awk '{ print $ 5 }' )
	if [ $InfDefault == $InfinUse ]
	then
		if ! ping -c 3 $HostMonitor > /dev/null 2>&1
		then 
			dhclient -r $InfDefault
			ip r del default
			dhclient $InfPPP
			echo "FailOver Active" | logger
		fi
	else 
		_FailBack
	fi
}
_FailBack () {
	if ! ip r | egrep $HostMonitor > /dev/null 2>&1
	then
		IpDefault=`egrep ^address1 $InfFile | cut -d ':' -f 2`
		GwDefault=`egrep ^gateway1 $InfFile | cut -d ':' -f 2`
		if ! ip a s | egrep $IpDefault > /dev/null 2>&1
		then
	        	ip a add $IpDefault dev $InfDefault	
		fi
		if [ -n $GwDefault ]
		then
			ip r add $HostMonitor via $GwDefault dev $InfDefault
			if ping -I $InfDefault -c 3 $HostMonitor > /dev/null 2>&1
			then
				dhclient -r $InfPPP
				dhclient $InfDefault
				echo "FailBack Active" | logger
			fi
			ip r del $HostMonitor
		fi
	fi
}
while true
do
	_Check_Info
	_FailOver
	sleep $DelayCheck
done
