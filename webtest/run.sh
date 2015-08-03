#!/bin/sh

while sleep 1; do
echo "##### Starting brunch..."
./node_modules/.bin/brunch watch --server
done
