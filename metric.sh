#!/bin/bash

sites=('maria.ru' 'rosa.ru' 'sina.ru')
API_PATH='/api/count'

# if we really need to start from the first second of the minute
#
#if [ $(date +"%S") != "00" ]
#then
#	echo "Waiting a new minute begins"
#	while [ $(date +"%S") != "00" ]; do echo -n "."; sleep 1; done
#	echo ""
#fi

while true
do
	for site in "${sites[@]}"
	do
		response=$(curl --connect-timeout 3 -s -w "\n%{http_code}" "http://${site}${API_PATH}")
		http_code=$(tail -n1 <<< "$response")
		if [ "$http_code" != 200 ]
		then
			continue
		fi
		metric=$(sed '$ d' <<< "$response" | sed 's/[^0-9]*//g')
		echo $(date +'%Y-%m-%d %H:%M:%S') ${site} ${metric}
	done

	sleep 60
done
