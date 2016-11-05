#!/bin/sh

set -e

vagrant gatling-rsync-auto &
docker logs werld --tail 100 -f &
wait
