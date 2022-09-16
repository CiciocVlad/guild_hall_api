FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Elixir requires UTF-8

#"===> Updating system packages"
RUN apt-get -qq update && apt-get -qq upgrade -y && apt-get install locales && locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# update and install software

#"===> Installing utilities"
RUN apt-get -qq update -y \
    && apt-get install -y dialog apt-utils curl wget git imagemagick \
    && apt-get install -y bsdmainutils build-essential make sudo vim gnupg2 unzip inotify-tools

#"==> Install ASDF plugin dependencies"
#"===> Installing ASDF common plugin deps"
RUN apt-get -qq install automake autoconf libreadline-dev libncurses-dev libssl-dev \
    libyaml-dev libxslt-dev libffi-dev libtool unixodbc-dev

#"===> Installing ASDF Erlang plugin deps"
RUN apt-get -qq update -y

RUN apt-get -qq install build-essential libncurses5-dev libgl1-mesa-dev \
    libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop

#"===> Installing ASDF Node.js plugin deps"
RUN apt-get -qq install dirmngr gpg

#"==> Install ASDF and plugins"
ENV WORK_DIR=/opt/crafting

WORKDIR $WORK_DIR

#"===> Installing ASDF"
RUN git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.profile && \
    source $HOME/.asdf/asdf.sh && \
    asdf plugin-add erlang && \
    asdf plugin-add elixir && \
    asdf plugin-add nodejs

#"===> Importing Node.js release team OpenPGP keys to main keyring"
# This can be flaky
# RUN /bin/bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

WORKDIR $WORK_DIR/guildhall
COPY .release-tool-versions .tool-versions
RUN source $HOME/.asdf/asdf.sh && asdf install &&  \
      mix local.hex --force && mix local.rebar --force