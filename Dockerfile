# escape=`
#Working on Windows, set escape character that doesn't interfere with file paths
# (must be first line of dockerfile, which is why this comment is second)

####### VERSIONS #######
# (When updating from jessie, if possible, don't use backports)
FROM debian:jessie
ARG DISTRO=jessie
ARG GOSU_VERSION=1.10
ARG NODE_VERSION=7.x

LABEL maintainer "jake.gillberg@gmail.com"

#Non-interactive console during docker build process
ARG DEBIAN_FRONTEND=noninteractive

####### BASIC DEV TOOLS / REQS #######
#Create regular user (dev)
RUN adduser --gecos "" --shell /bin/bash --disabled-password dev

#Install apt-utils so debconf doesn't complain about configuration for every
# other install
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
      apt-utils `
  && rm -rf /var/lib/apt/lists/*

#Show apt how to install backports (needed for gosu in jessie)
RUN `
  echo "deb http://ftp.debian.org/debian jessie-backports main" `
    > /etc/apt/sources.list.d/backports.list

#Install development tools and gosu for docker privilege fix
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    ca-certificates `
    curl `
    git `
    man `
    tmux `
  && apt-get -t jessie-backports install -y --no-install-recommends `
    gosu `
  && rm -rf /var/lib/apt/lists/*

#Configure git
COPY ./customize/.gitconfig /home/dev/.gitconfig
RUN `
  chown dev:dev /home/dev/.gitconfig `
  && chmod 0644 /home/dev/.gitconfig

#Configure LS colors
RUN dircolors -p > /home/dev/.dircolors.bak
COPY ./.dircolors /home/dev/.dircolors
RUN `
  chown dev:dev /home/dev/.dircolors* `
  && chmod 0644 /home/dev/.dircolors

#Start the entrypoint script
RUN echo '#!/bin/bash' > entrypoint.sh `
  && chmod 0700 /entrypoint.sh

####### EDITOR (VIM) #######
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
    && curl -Sso /home/dev/.vim/autoload/pathogen.vim https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim `
    #Configure pathogen
    #Delete following lines if your vimrc enables pathogen
      && echo '"Turn on plugin manager' >> /home/dev/.vimrc `
      && echo 'execute pathogen#infect()' >> /home/dev/.vimrc `
  # Install syntastic - syntax checks plugin
    && git clone --depth=1 https://github.com/vim-syntastic/syntastic.git /home/dev/.vim/bundle/syntastic `
    #Configure syntastic
    #Delete following lines if your vimrc configures syntastic
      && echo '' >> /home/dev/.vimrc `
      && echo '"Recommended settings for syntastic (https://github.com/vim-syntastic/syntastic)' >> /home/dev/.vimrc `
      && echo 'set statusline+=%#warningmsg#' >> /home/dev/.vimrc `
      && echo 'set statusline+=%{SyntasticStatuslineFlag()}' >> /home/dev/.vimrc `
      && echo 'set statusline+=%*' >> /home/dev/.vimrc `
      && echo '' >> /home/dev/.vimrc `
      && echo 'let g:syntastic_always_populate_loc_list = 1' >> /home/dev/.vimrc `
      && echo 'let g:syntastic_auto_loc_list = 1' >> /home/dev/.vimrc `
      && echo 'let g:syntastic_check_on_open = 1' >> /home/dev/.vimrc `
      && echo 'let g:syntastic_check_on_wq = 0' >> /home/dev/.vimrc `
  # Install sensible - mostly uncontentious defaults
    && git clone --depth=1 https://github.com/tpope/vim-sensible.git /home/dev/.vim/bundle/sensible `
  #Install syntax highlighting for solidity `
    && git clone --depth=1 https://github.com/tomlion/vim-solidity.git /home/dev/.vim/bundle/vim-solidity `
  # apply customized vimrc
    && echo '' >> /home/dev/.vimrc `
    && cat /home/dev/.vimrc.bak >> /home/dev/.vimrc
USER root

####### REMOTE ACCESS #######
# Install an ssh server
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    openssh-server `
  && rm -rf /var/lib/apt/lists/*

#Configure sshd
RUN cp /etc/ssh/sshd_config /etc/ssh/sshd_config.factorydefault
COPY ./sshd_config /etc/ssh/sshd_config
COPY ./customize/authorized_keys-dev /etc/ssh/authorized_keys/dev
RUN chmod 0644 /etc/ssh/sshd_config /etc/ssh/authorized_keys/dev
EXPOSE 22

#Start ssh on entry
RUN echo '/etc/init.d/ssh start' >> /entrypoint.sh

####### PAIRED PROGRAMING #######
# add a user for paired programming (guest)
RUN `
  adduser --gecos "" --shell /bin/bash --disabled-password guest

COPY ./customize/authorized_keys-guest /etc/ssh/authorized_keys/guest
RUN chmod 0644 /etc/ssh/authorized_keys/guest

#Install and configure wemux
RUN `
  git clone --depth=1 git://github.com/zolrath/wemux.git /usr/local/share/wemux `
  && ln -s /usr/local/share/wemux/wemux /usr/local/bin/wemux `
  && cp /usr/local/share/wemux/wemux.conf.example /usr/local/etc/wemux.conf.example
COPY ./wemux.conf /usr/local/etc/wemux.conf
RUN chmod 0644 /usr/local/etc/wemux.conf

####### ETHEREUM DEV #######
#Install node and reqs for node packages
#Use nodesource repository
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    apt-transport-https `
  && rm -rf /var/lib/apt/lists/*
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
  npm config set user dev -g `
  && npm config set prefix /home/dev/npm -g
ENV PATH="${PATH}:/home/dev/npm/bin"

USER dev
# Update npm before using it
RUN `
  npm install --no-optional -g `
    npm@latest `
  && npm cache clean

# Install testrpc and truffle
RUN `
  npm install -g --no-optional `
    git://github.com/ethereumjs/testrpc `
    git://github.com/trufflesuite/truffle `
  && npm cache clean
USER root

#Install the same solc that comes with truffle for syntax checking via syntastic.
#  (solcjs command line options not compatible with solc)
WORKDIR /tmp
RUN `
  rm -rf /tmp/* `
  && export SOLC_VERSION="$(/home/dev/npm/lib/node_modules/truffle/node_modules/solc/solcjs --version | sed 's/+.*//')" `
  && curl -LSso "./solidity_${SOLC_VERSION}.tar.gz" "https://github.com/ethereum/solidity/releases/download/v${SOLC_VERSION}/solidity_${SOLC_VERSION}.tar.gz" `
  && tar -zxf "./solidity_${SOLC_VERSION}.tar.gz" `
  && apt-get update `
  && apt-get install -y --no-install-recommends `
    cmake `
    libboost-all-dev `
  && rm -rf /var/lib/apt/lists/* `
  && cmake ./solidity_${SOLC_VERSION} `
  && make `
  && make install `
  && apt-get purge -y `
      cmake `
  && apt-get autoremove -y `
  && rm -rf /tmp/*
WORKDIR /

####### JAVA DEV #######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    openjdk-7-jdk `
  && rm -rf /var/lib/apt/lists/*

####### STARTUP #######
RUN `
  rm -rf /tmp/* `
  && echo 'exec gosu dev /bin/bash' >> /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]