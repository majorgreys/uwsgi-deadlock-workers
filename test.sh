#!/usr/bin/env bash

sudo apt install -qqyf software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update -qq
sudo apt install --no-install-recommends -qqyf python{2.7,3.5,3.6,3.7,3.8}-dev \
    python3.8-distutils \
    libpcre3-dev libjansson-dev libcap2-dev \
    curl check
make tests
make
/usr/bin/python2.7 -V
/usr/bin/python2.7 uwsgiconfig.py --plugin plugins/python base python27
/usr/bin/python3.5 -V
/usr/bin/python3.5 uwsgiconfig.py --plugin plugins/python base python35
/usr/bin/python3.6 -V
/usr/bin/python3.6 uwsgiconfig.py --plugin plugins/python base python36
/usr/bin/python3.7 -V
/usr/bin/python3.7 uwsgiconfig.py --plugin plugins/python base python37
/usr/bin/python3.8 -V
/usr/bin/python3.8 uwsgiconfig.py --plugin plugins/python base python38
ruby -v
UWSGICONFIG_RUBYPATH=ruby /usr/bin/python uwsgiconfig.py --plugin plugins/rack base rack251
./tests/travis.sh .github/workflows/test.yml
