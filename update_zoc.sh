#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get -y install jq curl zip
apt-get autoremove -y && apt-get autoclean -y

COIN="zeroone"
UPDATE_URL="https://github.com/zocteam/zeroonecoin/releases/download/v0.12.3.7-rc/"
FILENAME="zeroonecore-0.12.3.7-x86_64-linux-gnu.tar.gz"
BLOCKCHAIN_URL="https://files.01coin.io/mainnet/"
BLOCKCHAIN_FILE="bootstrap.dat.zip"
BLOCKHIGH_API="https://explorer.01coin.io/api/getblockcount"
COIN_SERVICE="${COIN}-cli"
COIN_DEAMON="${COIN}d -assumevalid=00000000370e7eb476c94ac49f0e226f905d0ab1815b379794e8eb0f36cc3119"
SOURCE_ZOC="/root/.zeroonecore/"
SOURCE_CLEAN="/root/zeroonecore-0.12.3/"
SOURCE="${SOURCE_CLEAN}bin/"
TARGET="/usr/local/bin/"
INSTALLED_VERSION="$(${COIN_SERVICE} -version | cut -d " " -f6)"
UPDATE_VERSION="v0.12.3.7-2EA1Dw40"

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

checkblockcount () {

get_blockhigh=$(curl $BLOCKHIGH_API)

	echo "  The current blockhigh on the net is now : ${get_blockhigh} ..."

get_blockcount=$(${COIN_SERVICE} getblockcount)

	echo "  The current blockhigh on the wallet is now : ${get_blockcount} ..."

	if [ ${get_blockcount}==${get_blockhigh} ]
	
	then
	
		echo "Wallet is synched !!!"
		sleep 3
		break

	else

		echo "Wallet is not synched ..."
		echo "Now reloading the blockchain ..."
		sleep 2
		checkshutdown
		cd $SOURCE_ZOC
		rm -rf blocks chainstate database fee_estimates.dat mempool.dat netfulfilled.dat db.log governance.dat mncache.dat peers* .lock zerooned.pid banlist.dat debug.log mnpayments.dat
		wget ${BLOCKCHAIN_URL}${BLOCKCHAIN_FILE}
		unzip ${BLOCKCHAIN_FILE} && rm ${BLOCKCHAIN_FILE}
	
	fi


}

if [ "$INSTALLED_VERSION"=="$UPDATE_VERSION" ] ; then

	echo "no update needed :)"
	checkblockcount
		
else
		
	prepair
	checkblockcount
	crontab_off
	checkshutdown
	update
	crontab_on
	# Start
	${COIN_DEAMON}
	checkrunning
	mnsync
	echo "update finish !!!"

fi
