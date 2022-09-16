#!/bin/sh

set -e

#"===> Updating system packages and locales"
sudo apt-get -qq update && sudo apt-get -qq upgrade -y && sudo apt-get install locales && sudo locale-gen en_US.UTF-8

#"===> Installing utilities"
sudo apt-get -qq update -y \
    && sudo apt-get install -y dialog apt-utils curl wget git \
    bsdmainutils build-essential make sudo vim gnupg2 unzip inotify-tools

#"==> Install ASDF plugin dependencies"
#"===> Installing ASDF common plugin deps"
sudo apt-get -qq install automake autoconf libreadline-dev libncurses-dev libssl-dev \
    libyaml-dev libxslt-dev libffi-dev libtool unixodbc-dev

#"===> Installing ASDF Erlang plugin deps"
sudo apt-get -qq update -y

sudo apt-get -qq install build-essential libncurses5-dev libgl1-mesa-dev \
    libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop

#"===> Installing ASDF Node.js plugin deps"
sudo apt-get -qq install dirmngr gpg

#"==> Install ASDF and plugins"
#"===> Installing ASDF"
git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.profile && \
    source $HOME/.asdf/asdf.sh && \
    asdf plugin-add erlang && \
    asdf plugin-add elixir && \
    asdf plugin-add nodejs

#"===> Importing Node.js release team OpenPGP keys to main keyring"
# This can be flaky
sudo /bin/bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

# Create the APP release folder with write permissions
sudo mkdir /opt/crafting
sudo chown ubuntu /opt/crafting
sudo chmod 755 /opt/crafting
mkdir /opt/crafting/guild_hall

# copy .release-tool-versions from local machine to ~/.tool-versions
# Run this manually after ASDF is installed
#asdf install && mix local.hex --force && mix local.rebar --force
