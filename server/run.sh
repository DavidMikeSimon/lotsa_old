#!/bin/sh

killall -9 beam
killall -9 epmd
touch ../webtest/server.build_time
elixir --cookie lotsa --name lotsa@127.0.0.1 --erl '-kernel inet_dist_listen_min 9001 inet_dist_listen_max 9001' -S mix run --no-halt
