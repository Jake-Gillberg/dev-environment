# escape=`
#Working on Windows, set escape character that doesn't interfere with file paths
# (must be first line of dockerfile, which is why this comment is second)

####### VERSIONS #######
FROM debian:stretch
ARG DISTRO=stretch
ARG NODE_VERSION=8.x

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

#Install development tools and gosu for docker privilege fix
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    apt-transport-https `
    ca-certificates `
    curl `
    git `
	gosu `
	locales `
    man `
    tmux `
	unzip `
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
RUN `
  rm -rf /etc/ssh/ssh_host* `
  && cp /etc/ssh/sshd_config /etc/ssh/sshd_config.factorydefault
COPY ./config/sshd_config /etc/ssh/sshd_config
COPY ./customize/authorized_keys-dev /etc/ssh/authorized_keys/dev
RUN chmod 0644 /etc/ssh/sshd_config /etc/ssh/authorized_keys/dev
EXPOSE 22

#Start ssh on entry
RUN `
  echo 'dpkg-reconfigure openssh-server' >> /entrypoint.sh `
  && echo '/etc/init.d/ssh start' >> /entrypoint.sh

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
COPY ./config/wemux.conf /usr/local/etc/wemux.conf
RUN chmod 0644 /usr/local/etc/wemux.conf

####### ETHEREUM DEV #######
#Install node and reqs for node packages
#Use nodesource repository
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
	gnupg2 `
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
  mkdir /npm `
  && chown dev:dev /npm `
  && npm config set user dev -g `
  && npm config set prefix /npm -g `
  && echo '' >> /home/dev/.profile `
  && echo 'if [ -d "/npm/bin" ] ; then' >> /home/dev/.profile `
  && echo '    PATH="/npm/bin:$PATH"' >> /home/dev/.profile `
  && echo 'fi' >> /home/dev/.profile

USER dev
# Update npm before using it
RUN `
  npm install --no-optional -g `
    npm@latest `
  && npm cache clean --force

# Install testrpc and truffle
RUN `
  npm install -g --no-optional `
    git://github.com/ethereumjs/testrpc `
    git://github.com/trufflesuite/truffle `
  && npm cache clean --force
USER root

#Install the same solc that comes with truffle for syntax checking via syntastic.
#  (solcjs command line options not compatible with solc)
WORKDIR /tmp
RUN `
  rm -rf /tmp/* `
  && export SOLC_VERSION="$(/npm/lib/node_modules/truffle/node_modules/solc/solcjs --version | sed 's/+.*//')" `
  && curl -LSso "./solidity_${SOLC_VERSION}.tar.gz" "https://github.com/ethereum/solidity/releases/download/v${SOLC_VERSION}/solidity_${SOLC_VERSION}.tar.gz" `
  && tar -zxf "./solidity_${SOLC_VERSION}.tar.gz" `
  && rm ./solidity_${SOLC_VERSION}.tar.gz `
  && apt-get update `
  && apt-get install -y --no-install-recommends `
    cmake `
    libboost-all-dev `
  && rm -rf /var/lib/apt/lists/* `
  && chown -R dev:dev ./*

RUN `
  cmake ./solidity_* `
  && make `
  && make install
RUN `
  apt-get purge -y `
      cmake `
  && apt-get autoremove -y `
  && rm -rf /tmp/*
WORKDIR /

####### JAVA / SCALA #######
RUN `
  apt-get update `
  && apt-get install -y --no-install-recommends `
    dirmngr `
    openjdk-8-jdk `
  && echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list `
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 `
  && apt-get update `
  && apt-get install -y --no-install-recommends `
    sbt `
  && rm -rf /var/lib/apt/lists/*

####### STARTUP #######
RUN `
  rm -rf /tmp/* `
  && echo 'exec gosu dev /bin/bash' >> /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]