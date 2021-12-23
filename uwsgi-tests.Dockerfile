FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y \
        make \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        curl \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        python-openssl \
        git \
        gdb \
        libpcre3-dev libjansson-dev libcap2-dev check \
        psmisc \
        virtualenv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/dpkg/dpkg.cfg.d/02apt-speedup

ENV PYENV_ROOT /root/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
RUN git clone -b v2.2.2 --depth 1 https://github.com/pyenv/pyenv.git /root/.pyenv && \
    cd /root/.pyenv && \
    git checkout `git describe --abbrev=0 --tags`
RUN pyenv install --keep --debug 2.7.18 \
    && pyenv install --keep 3.5.10 \
    && pyenv install --keep 3.6.15 \
    && pyenv install --keep 3.7.12 \
    && pyenv install --keep 3.8.12 \
    && pyenv global 2.7.18-debug \
    && pip install --upgrade pip

WORKDIR /src/
COPY ./uwsgi /src/

CMD ["/bin/bash"]
