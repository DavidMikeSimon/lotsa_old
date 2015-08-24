#!/bin/sh

ln -sf /tmp/vagrant/node_modules
ln -sf /tmp/vagrant/bower_components
mkdir -p /tmp/vagrant/webtest_build
ln -sf /tmp/vagrant/webtest_build _public

while sleep 1; do
echo "##### Starting brunch..."
./node_modules/.bin/brunch watch --server
done
