# escape=`
#Set escape character so that doesn't interfere with Windows file paths
# (must be first line of dockerfile, which is why this comment is second)

####### VERSIONS #######
FROM debian:stretch
ARG DISTRO=stretch
ARG INTELLIJ_VERSION=2018.1.1

LABEL maintainer "jake.gillberg@gmail.com"

####### USERS AND ARGS #######

# Match the Docker GID in the host system for bind mounting docker.sock
ARG DOCKER_GID=999

#Create regular user (dev) and groups
RUN `
  adduser --gecos "" --shell /bin/bash --disabled-password dev `
  && addgroup --gid ${DOCKER_GID} docker

#Non-interactive console during docker build process
ARG DEBIAN_FRONTEND=noninteractive

####### BASIC DEV TOOLS / REQS #######
#Install apt-utils so debconf doesn't complain about configuration for every
# other install
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
      apt-utils `
  && rm -rf /var/lib/apt/lists/*

#Install development tools and gosu for docker privilege fix
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    apt-transport-https `
    build-essential `
    ca-certificates `
    curl `
    dirmngr `
    git `
    gnupg2 `
    gosu `
    locales `
    man `
    software-properties-common `
    tmux `
    unzip `
    zip `
  && rm -rf /var/lib/apt/lists/*
  
#Set the locale
RUN `
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen `
  && dpkg-reconfigure locales `
  && echo ': "${LANG:=en_US.utf8}"; export LANG' >> /etc/profile

#Configure git
COPY ./customize/.gitconfig /home/dev/.gitconfig
RUN `
  chown dev:dev /home/dev/.gitconfig `
  && chmod 0644 /home/dev/.gitconfig

#Start the entrypoint script
RUN echo '#!/bin/bash' > entrypoint.sh `
  && chmod 0700 /entrypoint.sh

####### VIM #######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    vim `
  && rm -rf /var/lib/apt/lists/*
COPY ./customize/.vimrc /home/dev/.vimrc.bak
RUN chown dev:dev /home/dev/.vimrc.bak `
  && chmod 0644 /home/dev/.vimrc.bak

USER dev
RUN `
  # Install pathogen - plugin manager
    mkdir -p /home/dev/.vim/autoload /home/dev/.vim/bundle `
    && curl -LSo /home/dev/.vim/autoload/pathogen.vim https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim `
    #Configure pathogen
    #Delete following lines if your vimrc enables pathogen
      && echo '"Turn on plugin manager' >> /home/dev/.vimrc `
      && echo 'execute pathogen#infect()' >> /home/dev/.vimrc `
  # Install sensible - mostly uncontentious defaults
    && git clone --depth=1 https://github.com/tpope/vim-sensible.git /home/dev/.vim/bundle/sensible `
  # Install vim-scala - syntax highlighting and a couple other goodies for scala
    && git clone --depth=1 https://github.com/derekwyatt/vim-scala.git /home/dev/.vim/bundle/vim-scala `
  # apply customized vimrc
    && echo '' >> /home/dev/.vimrc `
    && cat /home/dev/.vimrc.bak >> /home/dev/.vimrc
USER root

####### Java #######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    openjdk-8-jdk-headless `
  && rm -rf /var/lib/apt/lists/*

####### SBT #######
RUN `
  echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list `
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 `
  && apt-get update `
  && apt-get install -y --no-install-recommends `
    sbt `
  && rm -rf /var/lib/apt/lists/*

####### BNFC #######
WORKDIR /tmp
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    alex `
    cabal-install `
    happy `
  && rm -rf /var/lib/apt/lists/* `
  && git clone --depth=1 https://github.com/BNFC/bnfc.git
WORKDIR /tmp/bnfc/source
RUN `
  cabal sandbox init --sandbox /bnfc `
  && cabal update `
  && cabal install
RUN `
  echo '' >> /home/dev/.profile `
  && echo 'if [ -d "/bnfc/bin" ] ; then' >> /home/dev/.profile `
  && echo '    PATH="/bnfc/bin:$PATH"' >> /home/dev/.profile `
  && echo 'fi' >> /home/dev/.profile

WORKDIR /

####### JFLEX #######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    jflex `
  && rm -rf /var/lib/apt/lists/*

####### DOCKER #######
# Note, the recommded way to run docker from inside a container is to
#  bind-mount /var/run/docker.sock from the host system
#  (http://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/)
RUN `
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - `
  && echo "deb [arch=amd64] https://download.docker.com/linux/debian ${DISTRO} stable" `
    > /etc/apt/sources.list.d/docker.list `
  && apt-get update `
  && apt-get install -y --no-install-recommends `
    docker-ce `
  && rm -rf /var/lib/apt/lists/* `
  && usermod -aG docker dev

####### INTELLIJ #######
WORKDIR /tmp
RUN `
  curl -LO https://download.jetbrains.com/idea/ideaIC-${INTELLIJ_VERSION}-no-jdk.tar.gz `
  && tar xf ideaIC-${INTELLIJ_VERSION}-no-jdk.tar.gz -C /opt/ `
  && rm -rf ideaIC-${INTELLIJ_VERSION}-no-jdk.tar.gz
WORKDIR /
  
####### GUI ######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    x11-apps `
  && rm -rf /var/lib/apt/lists* 

ENV DISPLAY :0.0
ENV XAUTHORITY /tmp/.docker.xauth

RUN `
  echo 'chmod 755 /tmp/.docker.xauth' >> /entrypoint.sh

####### STARTUP #######
RUN `
  rm -rf /tmp/* `
  && echo 'exec gosu dev /bin/bash' >> /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
