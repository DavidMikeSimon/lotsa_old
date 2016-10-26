#!/bin/sh

set -e
rerun -d 'lib,proto,test' -p '**/*.{ex,exs,proto}' --name werld -- elixir --sname werld -S mix run --no-halt
