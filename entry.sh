#!/bin/sh

set -e

while [ ! -f "/opt/rancher/config/server.json" ]; do
	sleep 1
done

sleep 5

exec /bin/consul agent "$@"
