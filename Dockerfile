FROM alpine:3.12
MAINTAINER Motion Bank <info@motionbank.org>

ARG JOBBER_VERSION=1.4.4
ARG DOCKER_VERSION=19.03.12
ARG DUPLICITY_VERSION=0.8.13
ARG DUPLICITY_SERIES=0.8
ARG MEGA_TOOLS_VERSION=1.10.3

RUN apk upgrade --update && \
    apk add \
      bash \
      tzdata \
      vim \
      tini \
      su-exec \
      gzip \
      tar \
      wget \
      curl \
      build-base \
      glib-dev \
      gmp-dev \
      asciidoc \
      curl-dev \
      tzdata \
      openssh \
      libressl-dev \
      libressl \
      duply \
      ca-certificates \
      libffi-dev \
      librsync-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-cryptography \
      librsync \
      librsync-dev \
      python3 \
      python3-dev \
      duplicity \
      py-pip && \
    pip install --upgrade pip && \
    pip install \
      setuptools \
      setuptools_scm \
      fasteners \
      PyDrive \
      chardet \
      azure-storage-blob \
      azure-storage-file-share \
      azure-storage-file-datalake \
      boto \
      lockfile \
      paramiko \
      pexpect \
      cryptography \
      python-keystoneclient \
      python-swiftclient \
      requests \
      requests_oauthlib \
      urllib3 \
      b2 \
      dropbox && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize && \
    # Install Duplicity
    curl -fSL "https://code.launchpad.net/duplicity/${DUPLICITY_SERIES}-series/${DUPLICITY_VERSION}/+download/duplicity-${DUPLICITY_VERSION}.tar.gz" -o /tmp/duplicity.tar.gz && \
    export DUPLICITY_SHA=71e07fa17dcf2002a0275bdf236c1b2c30143e276abfdee15e45a75f0adeefc9e784c76a578f90f6ed785f093f364b877551374204e70b930dd5d0920f7e1e75 && \
    echo 'Calculated checksum: '$(sha512sum /tmp/duplicity.tar.gz) && \
    echo "$DUPLICITY_SHA  /tmp/duplicity.tar.gz" | sha512sum -c - && \
    tar -xzvf /tmp/duplicity.tar.gz -C /tmp && \
    cd /tmp/duplicity-${DUPLICITY_VERSION} && python3 setup.py install && \
    # Install Jobber
    export CONTAINER_UID=1000 && \
    export CONTAINER_GID=1000 && \
    export CONTAINER_USER=jobber_client && \
    export CONTAINER_GROUP=jobber_client && \
    # Install tools
    apk add \
      go \
      git \
      curl \
      wget \
      make && \
    # Install Jobber
    addgroup -g $CONTAINER_GID jobber_client && \
    adduser -u $CONTAINER_UID -G jobber_client -s /bin/bash -S jobber_client && \
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Install Docker CLI
    curl -fSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz && \
    export DOCKER_SHA=2a20091beae5d549f942e9daa5f793b079f88460 && \
    echo 'Calculated checksum: '$(sha1sum /tmp/docker.tgz) && \
    echo "$DOCKER_SHA  /tmp/docker.tgz" | sha1sum -c - && \
	  tar -xzvf /tmp/docker.tgz -C /tmp && \
	  cp /tmp/docker/docker /usr/local/bin/ && \
    # Install MEGAtools
    curl -fSL "https://megatools.megous.com/builds/megatools-${MEGA_TOOLS_VERSION}.tar.gz" -o /tmp/megatools.tgz && \
    tar -xzvf /tmp/megatools.tgz -C /tmp && \
    cd /tmp/megatools-${MEGA_TOOLS_VERSION} && \
    ./configure && \
    make && \
    make install && \
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python3-dev \
      libffi-dev \
      libressl-dev \
      libressl \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      librsync-dev \
      make && \
    apk add \
        openssl && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

ENV VOLUMERIZE_HOME=/etc/volumerize \
    VOLUMERIZE_CACHE=/volumerize-cache \
    VOLUMERIZE_SCRIPT_DIR=/opt/volumerize \
    PATH=$PATH:/etc/volumerize \
    GOOGLE_DRIVE_SETTINGS=/credentials/cred.file \
    GOOGLE_DRIVE_CREDENTIAL_FILE=/credentials/googledrive.cred \
    GPG_TTY=/dev/console

USER root
WORKDIR /etc/volumerize
VOLUME ["/volumerize-cache"]
COPY imagescripts/ /opt/volumerize/
COPY scripts/ /etc/volumerize/
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
