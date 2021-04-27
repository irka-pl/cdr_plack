#
# No need to write `carton exec` because of the following:

ENV PERL5LIB=\$PERL5LIB:${perllibs} PERL_CARTON_PATH=/carton
ENV PATH "$PATH:/usr/bin"

#we don't need local, .git, docker
COPY cpanfile ./
COPY data ./
COPY etc ./
COPY lib ./
COPY t ./

RUN carton install \
    && rm -rf /root/.cpanm

RUN mkdir -p /data/store \
    && chmod +rx /data/store

#########

FROM perl-base AS cdr-perl-web
ARG workdir

COPY /docker/start-psgi-dev.sh /start-dev.sh
COPY /docker/start-psgi.sh /start.sh
RUN chmod +x /*.sh

#ENTRYPOINT ["bash","start-dev.sh"]
#ENTRYPOINT ["bash","ls"]