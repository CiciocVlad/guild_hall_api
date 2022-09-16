#!/bin/sh

set -e

export MIX_ENV=prod
export PORT=80

APP_NAME=guild_hall
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2 | tail -1 )"
echo $APP_NAME
echo $APP_VSN
mkdir -p rel/artifacts

rm -rf _build deps
cp .release-tool-versions .tool-versions

MIX_ENV=prod mix do clean, deps.get --only prod, compile --force
mix phx.digest --env=prod
echo $(pwd)
MIX_ENV=prod mix release $APP_NAME
cp "_build/prod/$APP_NAME-$APP_VSN.tar.gz" rel/artifacts/"prod-$APP_NAME-$APP_VSN.tar.gz"

# rm .tool-versions
rm -rf _build deps

exit 0
