#!/bin/sh

find lib proto -type f \! -name '*.sw?' \! -path 'lib/exprotoc/*' | entr -r mix run --no-halt
