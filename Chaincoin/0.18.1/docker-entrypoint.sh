#!/bin/bash
set -e

if [[ "$1" == "chaincoin-cli" || "$1" == "chaincoin-tx" || "$1" == "chaincoind" || "$1" == "test_chaincoin" ]]; then
	mkdir -p "$BITCOIN_DATA"

	cat <<-EOF > "$BITCOIN_DATA/chaincoin.conf"
	${CONFIG_PREFIX}
	printtoconsole=1
	rpcallowip=::/0
	${BITCOIN_EXTRA_ARGS}
	EOF
	chown bitcoin:bitcoin "$BITCOIN_DATA/chaincoin.conf"

	# ensure correct ownership and linking of data directory
	# we do not update group ownership here, in case users want to mount
	# a host directory and still retain access to it
	chown -R bitcoin "$BITCOIN_DATA"
	ln -sfn "$BITCOIN_DATA" /home/bitcoin/.chaincoincore
	chown -h bitcoin:bitcoin /home/bitcoin/.chaincoincore

	exec gosu bitcoin "$@"
else
	exec "$@"
fi