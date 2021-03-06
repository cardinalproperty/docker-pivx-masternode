FROM ubuntu:xenial
MAINTAINER Oliver Gugger <gugger@gmail.com>

ARG USER_ID
ARG GROUP_ID

ENV HOME /pivx

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} pivx \
	&& useradd -u ${USER_ID} -g pivx -s /bin/bash -m -d /pivx pivx

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

RUN set -x apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PIVX_VERSION 2.2.1
RUN wget -O /tmp/pivx.tar.gz "https://github.com/PIVX-Project/PIVX/releases/download/v$PIVX_VERSION/pivx-$PIVX_VERSION-x86_64-linux-gnu.tar.gz" \
    && cd /tmp/ \
    && tar zxvf pivx.tar.gz \
    && mv /tmp/pivx-$PIVX_VERSION/bin/pivx* /usr/local/bin/

RUN apt-get update && apt-get install -y unzip \
    && wget -O /opt/blockchain.zip "http://108.61.216.160/cryptochainer.chains/chains/PIVX_blockchain.zip"

ADD ./bin /usr/local/bin

VOLUME ["/pivx"]

EXPOSE 51472

WORKDIR /pivx

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["pivx-oneshot.sh"]
