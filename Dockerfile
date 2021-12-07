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
ARG PY=2.7.17
# install both debug and non-debug versions of cpython for testing
RUN pyenv install --keep --debug $PY && \
    pyenv install --keep $PY && \
    pyenv global $PY
# gdb debugging of cpython when running uwsgi
# RUN pyenv global 2.7.17-debug
# ENV CFLAGS=-I/root/.pyenv/versions/2.7.17-debug/include/python2.7
ARG UWSGI_GIT=majorgreys/uwsgi@4fe3802912726012e632174292ccf765e318f494
RUN pip install git+https://github.com/$UWSGI_GIT
# For local development
# COPY ./uwsgi /src/uwsgi/
# RUN pip install /src/uwsgi
COPY . /app/
WORKDIR /app/
# Ensures that sitecustomize.py will be loaded when Python interpreter is initialized
ENV PYTHONPATH=/app/
EXPOSE 8080
# better gdb defaults
# COPY ./.gdbinit /root/
RUN wget -P ~ https://git.io/.gdbinit && pip install pygments
CMD ["./start.sh"]
