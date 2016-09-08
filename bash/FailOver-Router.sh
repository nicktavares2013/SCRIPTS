#!/bin/bash

# 
TimeOut=10
Tables=( 100 101 )
Inf=( wlp6s0 )
Gws=( 10.0.0.1 20.0.0.1 )
HostTest="8.8.8.8"

_IPv4_Inf () {
	i=0
	for inf in ${Inf[@]}
	do
		Address_Inf[$i]=`ip -4 -o a s dev $inf | awk '{ print $ 4 }' | cut -d '/' -f 1 `
		let i++
	done
}

_Check_Default () {
	Router=` ip -4 -o r | egrep ^default | awk '{ print $ 3 }' `
	if ping -c 4 $HostTest > /dev/null 2>&1 && [ ${Gws[0]} == $Router ]
	then
		sleep $TimeOut
		_Main
	else
		_FailOver
	fi
}
_Check_Links () {
	i=0
	for inf in ${Inf[@]}
	do
		ip r add $HostTest via ${Gws[$i]}
		if ping -c 2 -I $inf $HostTest > /dev/null 2>&1
		then
			echo $i
			break
		else
			let i++
		fi
	done
}

_FailOver () {

}
