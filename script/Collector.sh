#!/bin/bash
# script to collect the cpu and memory usage of the given tool
TOOL=`hostname`
service_user='osboxes'
if [ ! -z "$1" ]
then
TOOL=$1
fi

# add load average
var=`cat /proc/loadavg | cut -d' ' -f1 | xargs echo $TOOL"_load_average" `
var=$var

# collect cpu usage
# top displays wrong results on the first iteration – run it twice an grep away the firt output
LINES=`top -bcn2 -u ${service_user} | awk '/^top -/ { p=!p } { if (!p) print }' | tail -n +8`

while read -r LINE
do
IN=`echo "$LINE" | tr -s ' '`
PID=`echo $IN | cut -d ' ' -f1 `
CMD=`echo $IN | cut -d ' ' -f12 `
CPU=`echo $IN | cut -d ' ' -f9 `
MEM=`echo $IN | cut -d ' ' -f10 `
var=$var$(printf "${TOOL}_cpu_usage{process=\"$CMD\", pid=\"$PID\"} $CPU\n")
var="$var"

var=$var$(printf "${TOOL}_memory_usage{process=\"$CMD\", pid=\"$PID\"} $MEM\n")
var="$var"
done <<< "$LINES"

echo $var

# push to the prometheus pushgateway
curl –noproxy "*" -X POST -H "Content-Type: text/plain" --data "$var" http://192.168.31.50:9091/metrics/job/top/instance/machine
