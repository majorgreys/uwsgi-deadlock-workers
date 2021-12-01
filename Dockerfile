FROM debian:buster-slim
# Use pyenv for building CPython with pydebug
ENV DEBIAN_FRONTEND=noninteractive
ENV PYENV_ROOT /root/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN git clone https://github.com/pyenv/pyenv.git /root/.pyenv && \
    cd /root/.pyenv && \
    git checkout `git describe --abbrev=0 --tags`
RUN pyenv install --keep --debug 2.7.17 && \
    pyenv global 2.7.17-debug
COPY uwsgi /src/uwsgi/
RUN pip install -e /src/uwsgi
COPY . /app/
WORKDIR /app/
ENV PYTHONPATH=/app/
# ENV PYTHONTHREADDEBUG=1
EXPOSE 8080
COPY ./.gdbinit /root/
# RUN wget -P ~ https://git.io/.gdbinit && pip install pygments
CMD ["./start.sh"]
