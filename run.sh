#!/bin/sh

set -e

#ln -sf /tmp/vagrant/deps
#ln -sf /tmp/vagrant/_build

mix local.hex --force
mix local.rebar --force
mix deps.get
mix deps.compile

find lib proto -type f \! -name '*.sw?' \! -path 'lib/exprotoc/*' | entr -r mix run --no-halt
