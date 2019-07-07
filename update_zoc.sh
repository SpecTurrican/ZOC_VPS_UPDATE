#!/bin/bash

COIN="zeroone"
UPDATE_URL="https://github.com/zocteam/zeroonecoin/releases/download/v0.12.3.5/"
FILENAME="zeroonecore-0.12.3.5-x86_64-linux-gnu.tar.gz"
COIN_SERVICE="${COIN}-cli"
COIN_DEAMON="${COIN}d"
SOURCE="/root/zeroonecore-0.12.3/bin/"
TARGET="/usr/local/bin/"
INSTALLED_VERSION="$(${COIN_SERVICE} getinfo | jq .version)"
UPDATE_VERSION="120305"

prepair () {

	# apt-get update && apt-get -y upgrade

	cd /root/
	wget ${UPDATE_URL}${FILENAME}
	tar -xzvf $FILENAME && rm ${FILENAME}


}

update () {

	cp ${SOURCE}${COIN_DEAMON} $TARGET
	cp ${SOURCE}${COIN_SERVICE} $TARGET


}

checkrunning () {

	#
	# Is the service running ?

	echo " ... waiting of ${COIN}.service ... please wait!..."

	while ! ${COIN_SERVICE} getinfo >/dev/null 2>&1; do
		sleep 5
		error=$(${COIN_SERVICE} getinfo 2>&1 | cut -d: -f4 | tr -d "}")
		echo " ... ${COIN}.service is on : ${error}"
		sleep 2
	done

	echo "${COIN}.service is running !"


}

checkshutdown () {

${COIN_SERVICE} stop

	#
	# Is the service off ?

	echo " ... waiting of ${COIN}.service shutdown... please wait!..."

	while ${COIN_SERVICE} getinfo >/dev/null 2>&1; do
		error=$(${COIN_SERVICE} getinfo 2>&1 | cut -d: -f4 | tr -d "}")
		echo " ... ${COIN}.service is on : ${error}"
	done

	echo "${COIN}.service is shutdown !"
	sleep 10


}

crontab_off () {

	crontab -l >> crontab.txt
	crontab -r
	# '#' am Anfang jeder Zeile einfügen
	sed -i 's@^@#@g' crontab.txt
	crontab -i crontab.txt


}

crontab_on () {

	crontab -r
	# '#' am Anfang jeder Zeile entfernen
	sed -i 's@^#@@g' crontab.txt
	crontab -i crontab.txt


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

if [ "$INSTALLED_VERSION" -lt "$UPDATE_VERSION" ]

	then

		prepair
		crontab_off
		checkshutdown
		update
		crontab_on

		echo "update finish"

		${COIN_DEAMON}

		checkrunning
		mnsync

	else

		echo "no update"

fi
