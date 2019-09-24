#!/bin/bash

apt-get update
apt-get autoremove -y && apt-get autoclean -y
apt-get -y install jq >/dev/null

COIN="zeroone"
UPDATE_URL="https://github.com/zocteam/zeroonecoin/releases/download/v0.12.3.6/"
FILENAME="zeroonecore-0.12.3.6-x86_64-linux-gnu.tar.gz"
COIN_SERVICE="${COIN}-cli"
COIN_DEAMON="${COIN}d"
SOURCE_CLEAN="/root/zeroonecore-0.12.3/"
SOURCE="${SOURCE_CLEAN}bin/"
TARGET="/usr/local/bin/"
#INSTALLED_VERSION="$(${COIN_SERVICE} getinfo | jq .version)"
UPDATE_VERSION="120306"

prepair () {

	cd /root/
	rm ${SOURCE_CLEAN} -r >/dev/null
	wget ${UPDATE_URL}${FILENAME}
	tar -xzvf ${FILENAME} && rm ${FILENAME}


}

update () {

	sleep 1
	cp ${SOURCE}${COIN_DEAMON} $TARGET
	cp ${SOURCE}${COIN_SERVICE} $TARGET


}

checkrunning () {

	#
	# Is the service running ?

	echo " ... waiting of ${COIN}.service ... please wait!..."

	while ! ${COIN_SERVICE} getinfo >/dev/null 2>&1; do
		sleep 5
		error=$(${COIN_SERVICE} getinfo >/dev/null 2>&1 | cut -d: -f4 | tr -d "}")
		echo " ... ${COIN}.service is on : ${error}"
		sleep 2
	done

	echo "${COIN}.service is running !"
	sleep 2


}

checkshutdown () {

${COIN_SERVICE} stop

	#
	# Is the service off ?

	echo " ... waiting of ${COIN}.service shutdown... please wait!..."

	while ${COIN_SERVICE} getinfo >/dev/null 2>&1; do
		error=$(${COIN_SERVICE} getinfo >/dev/null 2>&1 | cut -d: -f4 | tr -d "}")
		echo " ... ${COIN}.service is on : ${error}"
		sleep 1
	done

	echo "${COIN}.service is shutdown !"
	sleep 5


}

crontab_off () {

	rm crontab.txt >/dev/null
	crontab -l >> crontab.txt
	crontab -r
	# '#' Insert at the beginning of each line
	sed -i 's@^@#@g' crontab.txt
	crontab -i crontab.txt


}

crontab_on () {

	crontab -r
	# '#' Remove at the beginning of each line
	sed -i 's@^#@@g' crontab.txt
	crontab -i crontab.txt
	rm crontab.txt >/dev/null


}
mnsync () {

mnsy=$(${COIN_SERVICE} mnsync status | jq .AssetName | tr -d '"')
while true; do

	if [ ${mnsy} = "MASTERNODE_SYNC_FINISHED" ]

	then

		echo "mnsync finish !!!"
		sleep 5
		break

	else

		sleep 5
		mnsy=$(${COIN_SERVICE} mnsync status | jq .AssetName | tr -d '"')
		echo "... pls wait !!! mnsync is : ${mnsy}"

	fi

done


}

#if [ "$INSTALLED_VERSION" -lt "$UPDATE_VERSION" ]
#
#	then

		prepair
		crontab_off
		checkshutdown
		update
		crontab_on
		# Start
		${COIN_DEAMON} >/dev/null
		checkrunning
		mnsync
		# Clean Update
		rm ${SOURCE_CLEAN} -r >/dev/null
		echo "update finish"

#	else
#
#		echo "no update"
#
#fi
