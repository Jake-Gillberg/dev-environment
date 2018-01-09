# escape=`
#Working on Windows, set escape character that doesn't interfere with file paths
# (must be first line of dockerfile, which is why this comment is second)

####### VERSIONS #######
FROM debian:stretch

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
    gnupg2 `
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

####### SCALA (and Java) #######
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

####### INTELLIJ #######
WORKDIR /tmp
RUN `
  curl -LO https://download.jetbrains.com/idea/ideaIC-2017.3.2.tar.gz `
  && tar xf ideaIC-2017.3.2.tar.gz -C /opt/ `
  && rm -rf ideaIC-2017.3.2.tar.gz
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
