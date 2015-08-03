#!/bin/sh

set -e

if [ `whoami` != "vagrant" ]; then
	echo "You must run this inside the vagrant machine! See README.md"
	exit
fi

cd /vagrant

yes | mix deps.get
yes | mix deps.compile

cd webtest
npm install
yes | ./node_modules/.bin/bower install
