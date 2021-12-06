#!/usr/bin/env bash

UWSGI=$(dirname $(pyenv which python))/uwsgi

# gdb --args \
$UWSGI --ini /app/uwsgi.ini
