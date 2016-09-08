#!/bin/bash
# LoadBalance Proxy HTTP

PortService=3128
Servers=( 10.0.0.2 10.0.0.3 10.0.0.4 )
TimeOut=10

# Functions

_Check_Servers () {
  > /tmp/fails.tmp
  for i in ${Servers[@]}
  do
    telnet $i $PortService << EOF
GET
EOF
    if [ $? -ne 0 ]
    then
       echo $i >> /tmp/fails.tmp
    fi
  done
  Fails=( `cat /tmp/fails.tmp`)
  rm -f /tmp/fails.tmp
}
_Remove_Fails (){
  _Proporcional
  if [ ! -z ${Fails[@]} ]
  then
    for fail in ${Fails[@]}
    do
      iptables -t nat -D PREROUTING -p tcp -m statistic \
      --mode random --probability $P --dport 80 -j DNAT --t ${i}:${PortService}
}
_Proporcional () {
  P=`echo ${Servers[@]} | wc -w`
  P=$(( 100 / $P ))
  P="0.${P}"
}
_Add_Servers () {
  _Proporcional
  for i in ${Servers}
  do
    iptables -t nat -A PREROUTING -p tcp -m statistic \
    --mode random --probability $P --dport 80 -j DNAT --to ${i}:${PortService}
    let X++
  done
}
