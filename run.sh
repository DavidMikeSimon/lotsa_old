#!/bin/sh

ln -sf /tmp/vagrant/deps
ln -sf /tmp/vagrant/_build

find lib proto -type f \! -name '*.sw?' \! -path 'lib/exprotoc/*' | entr -r mix run --no-halt
