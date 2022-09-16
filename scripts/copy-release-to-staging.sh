#!/bin/sh

set -e

echo $(pwd)

APP_NAME=guild_hall
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2 | tail -1)"

echo $APP_NAME
echo $APP_VSN

ssh guildhall-staging "mkdir -p /opt/crafting/$APP_NAME/$APP_VSN"
scp -i ~/.ssh/id_rsa rel/artifacts/"prod-$APP_NAME-$APP_VSN.tar.gz" ubuntu@ec2-34-250-66-118.eu-west-1.compute.amazonaws.com:/opt/crafting/$APP_NAME/"$APP_VSN"/"$APP_NAME-$APP_VSN.tar.gz"
ssh guildhall-staging "cd /opt/crafting/$APP_NAME/$APP_VSN && tar xvf $APP_NAME-$APP_VSN.tar.gz && rm -r $APP_NAME-$APP_VSN.tar.gz"
