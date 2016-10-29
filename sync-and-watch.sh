#!/bin/sh

set -e

vagrant gatling-rsync-auto &
docker logs werld -f &
wait
