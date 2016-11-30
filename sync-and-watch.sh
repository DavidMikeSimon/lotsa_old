#!/bin/sh

set -e

vagrant gatling-rsync-auto &
docker logs werld --tail 30 -f &
wait
