FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
    && apt-get install -qqyf software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get install --no-install-recommends -qqyf python2.7-dev python3.5-dev \
        python3.6-dev python3.7-dev python3.8-dev \
        python3.8-distutils \
        libpcre3-dev libjansson-dev libcap2-dev \
        curl check \
        build-essential \
        psmisc \
        virtualenv \
        git

WORKDIR /src/
COPY ./uwsgi/ /src/

RUN make \
    && /usr/bin/python2.7 uwsgiconfig.py --plugin plugins/python base python27 \
    && /usr/bin/python3.5 uwsgiconfig.py --plugin plugins/python base python35 \
    && /usr/bin/python3.6 uwsgiconfig.py --plugin plugins/python base python36 \
    && /usr/bin/python3.7 uwsgiconfig.py --plugin plugins/python base python37 \
    && /usr/bin/python3.8 uwsgiconfig.py --plugin plugins/python base python38

# RUN git clone -b 2.0.20 --depth 1 https://github.com/unbit/uwsgi /src/

CMD ["/bin/bash"]
