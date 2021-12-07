#!/usr/bin/env bash

UWSGI=$(dirname $(pyenv which python))/uwsgi

# Prepend `gdb --args` for debugging
# gdb --args \
$UWSGI --ini /app/uwsgi.ini
