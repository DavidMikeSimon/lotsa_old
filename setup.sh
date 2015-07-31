#!/bin/sh

set -e

if [ `whoami` != "vagrant" ]; then
	echo "You must run this inside the vagrant machine! See README.md"
	exit
fi

cd /vagrant

mkdir -p /home/vagrant/tmp/werld/_build
ln -nsf /home/vagrant/tmp/werld/_build _build
mkdir -p /home/vagrant/tmp/werld/deps
ln -nsf /home/vagrant/tmp/werld/deps deps
mkdir -p /home/vagrant/tmp/werld/exprotoc
ln -nsf /home/vagrant/tmp/werld/exprotoc lib/exprotoc
mkdir -p /home/vagrant/tmp/werld/node_modules
ln -nsf /home/vagrant/tmp/werld/node_modules webtest/node_modules
mkdir -p /home/vagrant/tmp/werld/bower_components
ln -nsf /home/vagrant/tmp/werld/bower_components webtest/bower_components

yes | mix deps.get

cd webtest
npm install
yes | ./node_modules/.bin/bower install

cd /vagrant

#tmux attach -t werld || tmux new -s werld "teamocil --layout ./teamocil.yml"
