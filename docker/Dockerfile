# Make sure the Docker container has access to the outside Internet
# in order to gather packages from CPAN.

ARG workdir=/usr/src/app
FROM perl:latest AS perl-base
ARG workdir

WORKDIR ${workdir}

# upgrade cpanm and install Carton
RUN cpanm --self-upgrade --notest --quiet \
    && cpanm Carton --notest --quiet \
    && mkdir /carton \
    && rm -fr /root/.cpanm /tmp/*

#   Docker

#
# No need to write `carton exec` because of the following:

ENV PERL5LIB=\$PERL5LIB:/carton/lib/perl5 PERL_CARTON_PATH=/carton
ENV PATH "$PATH:/usr/bin:/carton/bin"

#we don't need local, .git, docker
RUN mkdir -p ./data/init \
    && chmod +rx ./data/init

COPY cpanfile ./
COPY data/init/ ./data/init/
COPY etc/ ./etc/
COPY lib/ ./lib/
COPY t/ ./t/
COPY psgi.pl ./

RUN carton install \
    && rm -rf /root/.cpanm

RUN mkdir -p ./data/store \
    && chmod +rx ./data/store

#########

FROM perl-base AS cdr-perl-web
ARG workdir

COPY /docker/start-psgi-dev.sh ./start-dev.sh
COPY /docker/start-psgi.sh ./start.sh
RUN chmod +x ./*.sh

#ENTRYPOINT ["bash","start-dev.sh"]
#ENTRYPOINT ["sh", "/usr/src/app/start-dev.sh"]