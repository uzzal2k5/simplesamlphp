#!/usr/bin/env bash

set -e

exec "$@"
cmd="/etc/init.d/php7.2-fpm start"
exec "$cmd"