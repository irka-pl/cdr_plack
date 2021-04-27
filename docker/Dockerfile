# Make sure the Docker container has access to the outside Internet
# in order to gather packages from CPAN.

ARG workdir=/usr/src/app
FROM perl:5.20.2 AS perl-base
ARG workdir

WORKDIR ${workdir}

# upgrade cpanm and install Carton
RUN cpanm --self-upgrade --notest --quiet \
    && cpanm Carton --notest --quiet \
    && mkdir /carton \
    && rm -fr /root/.cpanm /tmp/*

#   Docker

#RUN apt-get -qq update && apt-get install -yq --no-install-recommends \
#        apt-transport-https \
#        ca-certificates \
#        curl \
#        gnupg2 \
#        software-properties-common \
#    && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
#    && add-apt-repository \
#        "deb [arch=amd64] https://download.docker.com/linux/debian \
#        jessie \
#        stable" \
#    && apt-get -qq update \
#    && apt-get install -yq --no-install-recommends docker-ce \
#    && apt-get -qq clean \
#    && rm -rf /var/lib/apt/lists/*
#
#RUN apt-get -qq update && apt-get install -yq --no-install-recommends \
#    build-essential \
#    gcc \
#    gcc-multilib \
#    uuid \
#    uuid-dev \
#    perl \
#    perl-doc \
#    libssl-dev \
#    telnet \
#    libarchive-zip-perl \
#    libcrypt-ssleay-perl \
#    libclass-methodmaker-perl \
#    libdata-dump-perl \
#    iputils-ping \
#    module-init-tools \
#    unzip \
#    && apt-get -qq clean \
#    && rm -rf /var/lib/apt/lists/* \
#    && echo 'FAKE_NAME="Ubuntu"' >> /etc/os-release \
#    && mkdir -p /carton/lib/perl5/ \
#    && rm -rf ./docker

# No need to write `carton exec` because of the following:
ENV PERL5LIB=\$PERL5LIB:${perllibs} PERL_CARTON_PATH=/carton

COPY * ./
#COPY cpanfile ./
RUN carton install \
    && rm -rf /root/.cpanm

RUN mkdir -p /data/store \
    && chmod +rx /data/store
# COPY lib lib
# COPY t t

#########

FROM perl-base AS cdr-perl-web
ARG workdir

COPY docker/psgi-dev.sh /start-dev.sh
COPY docker/psgi-prod.sh /start.sh
RUN chmod +x /*.sh
