#!/bin/sh

set -e

vagrant gatling-rsync-auto &
vagrant exec sudo tail -f /var/log/syslog &
wait
