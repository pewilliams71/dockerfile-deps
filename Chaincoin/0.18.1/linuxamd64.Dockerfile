FROM debian:stretch-slim as builder

RUN groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget \
	&& rm -rf /var/lib/apt/lists/*

ENV CHAINCOIN_VERSION 0.18.1
ENV CHAINCOIN_URL https://github.com/chaincoin/chaincoin/releases/download/v0.18/chaincoin-0.18.1-x86_64-linux-gnu.tar.gz
ENV CHAINCOIN_SHA256 9a98fd81ee950e7beb29c38578b005f353c593c3b38be1a12c39684a3968db17

# install chaincoin binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO chaincoin.tar.gz "$CHAINCOIN_URL" \
	&& mkdir bin \
	&& echo "$CHAINCOIN_SHA256 chaincoin.tar.gz" | sha256sum -c - \
	&& tar -xzvf chaincoin.tar.gz -C /tmp/bin --strip-components=2 "chaincoin-$CHAINCOIN_VERSION/bin/chaincoin-cli" "chaincoin-$CHAINCOIN_VERSION/bin/chaincoind" \
	&& echo "chaincoin.tar.gz" | sha256sum \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
	&& echo "0b843df6d86e270c5b0f5cbd3c326a04e18f4b7f9b8457fa497b0454c4b138d7 gosu" | sha256sum -c -

FROM debian:stretch-slim
COPY --from=builder "/tmp/bin" /usr/local/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.chaincoin \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.chaincoin
VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 11994 11995 21994 21995 
CMD ["chaincoind"]
