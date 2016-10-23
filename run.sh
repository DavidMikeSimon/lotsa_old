#!/bin/sh

set -e
rerun -d 'lib,proto,test' -p '**/*.{ex,exs,proto}' --name werld -- mix run --no-halt
