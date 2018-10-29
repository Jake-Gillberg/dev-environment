# escape=`
#Set escape character so that doesn't interfere with Windows file paths
# (must be first line of dockerfile, which is why this comment is second)

####### VERSIONS #######
FROM debian:stretch
ARG DISTRO=stretch

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
 
####### GUI ######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    x11-apps `
  && rm -rf /var/lib/apt/lists/*

ENV DISPLAY :0.0
ENV XAUTHORITY /tmp/.docker.xauth

RUN `
  echo 'chmod 755 /tmp/.docker.xauth' >> /entrypoint.sh

####### DappHub toolkit #######
RUN `
  mkdir -m 0755 /nix `
  && chown dev /nix

USER dev
ENV USER=dev
RUN `
  curl https://nixos.org/nix/install | sh

RUN `
  curl https://dapp.tools/install | sh

USER root

####### NODE #######
ARG NODE_VERSION=8.x
RUN `
  curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key `
    | apt-key add - `
  && echo "deb https://deb.nodesource.com/node_${NODE_VERSION} ${DISTRO} main" `
    > /etc/apt/sources.list.d/nodesource.list `
  && echo "deb-src https://deb.nodesource.com/node_${NODE_VERSION} ${DISTRO} main" `
    >> /etc/apt/sources.list.d/nodesource.list
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    g++ `
    nodejs `
    make `
    python `
  && rm -rf /var/lib/apt/lists/*

#Configuare npm
RUN `
  mkdir /npm `
  && chown dev:dev /npm `
  && npm config set user dev -g `
  && npm config set prefix /npm -g `
  && echo '' >> /home/dev/.profile `
  && echo 'if [ -d "/npm/bin" ] ; then' >> /home/dev/.profile `
  && echo '    PATH="/npm/bin:$PATH"'   >> /home/dev/.profile `
  && echo 'fi'                          >> /home/dev/.profile

USER dev
# Update npm before using it
RUN `
  npm install --no-optional -g `
    npm@latest `
  && npm cache clean --force
USER root

####### TRUFFLE #######
USER dev
RUN `
  npm install -g --no-optional `
    truffle `
    ganache-cli `
  && npm cache clean --force
USER root

####### STARTUP #######
RUN `
  rm -rf /tmp/* `
  && echo 'exec gosu dev /bin/bash' >> /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
