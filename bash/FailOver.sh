#!/bin/bash

# Autor     : Nícolas Tavares Pinto
# Data      : 25/02/2013
# Alteração : 02/07/2015
# Licença   : GPLv2 or letter

# Script de failover sobre interfaces. 

# Este script testa, e faz failover e failback de gateway nas interfaces. 

TimeOut=10
# Informe as interfaces de rede, sendo a primeira o link principal
Inf=( eth1 eth2 eth3 )
# Informe os gateways das interfaces separados por espaço. Obs.: os gateways devem ser informados na ordem. 
Gws=( 172.16.170.39 192.168.56.1 172.16.170.81 )


# ----------------------------------- Não alterar ----------------------------------------------------------
HostTest="8.8.8.8"
LogFile="/var/log/failover.log"
PidFile="/var/run/failover.pid"
_Check_Traffic () {
	ping -c 4 $HostTest > /dev/null 2>&1
	if  [ $? -eq 0 ]
	then
		echo 0
	else
		echo 1
	fi
}
_Check_Host () {
	ping -c 4 -I $1 $HostTest > /dev/null 2>&1
	if  [ $? -eq 0 ]
	then
		echo 0
	else
		echo 1
	fi
}
_FailOver () {
	if [ `_Check_Traffic` -eq 0 ]
	then
		echo "`date "+%F %H:%M:%S"` FailOver Mantido" >> $LogFile 
		sleep $TimeOut
	else
		i=1
		for inf in ${Inf[@]}
		do
			ip r del default > /dev/null 2>&1
			ip r add default via ${Gws[$i]} dev ${Inf[$i]}
			if [ `_Check_Traffic` -eq 0 ]
			then
				echo "`date "+%F %H:%M:%S"` FailOver Ativado" >> $LogFile 
				break
			else
				echo "`date "+%F %H:%M:%S"` Link ${Inf[$i]} fora">> $LogFile
				let i++
			fi
		done
		sleep $TimeOut
	fi
	_FailBack
}
_FailBack () {
	if [ ${Gws[0]} != `ip -4 -o r | egrep default | awk '{ print $ 3 }'` ]
	then
		ip r add $HostTest via ${Gws[0]} dev ${Inf[0]}
		if [ `_Check_Host ${Inf[0]}` -eq 0 ]
		then 
			ip r del $HostTest via ${Gws[0]} dev ${Inf[0]}
			echo "`date "+%F %H:%M:%S"` Verificando FailBack" >> $LogFile
			_Main
		else
			 ip r del $HostTest via ${Gws[0]} dev ${Inf[0]}
			_FailOver
		fi
	fi
}
_Main () {
	ip r del default 
	ip r add default via ${Gws[0]} dev ${Inf[0]}
	if [ `_Check_Traffic` -ne 0 ]
	then
		_FailOver
	else
		echo "`date "+%F %H:%M:%S"` Link principal ativo" >> $LogFile
	fi
	echo "$$" > $PidFile
	sleep $TimeOut
	_Main
}
_Stop () {
	kill `cat $PidFile`
}
case $1 in 
	"start" ) echo "`date "+%F %H:%M:%S"` [failover] - [start]" >> $LogFile && _Main ;;
	"stop" ) echo "`date "+%F %H:%M:%S"` [failover] - [stop]" >> $LogFile && _Stop ;;
	* ) echo "$0 {start|stop}";;
esac
