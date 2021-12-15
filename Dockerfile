FROM debian:buster-slim

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/dpkg/dpkg.cfg.d/02apt-speedup

# install pyenv
ENV PYENV_ROOT /root/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv.git /root/.pyenv && \
    cd /root/.pyenv && \
    git checkout `git describe --abbrev=0 --tags`

# use pyenv to install both debug and non-debug versions of cpython
ARG PY=2.7.17
RUN pyenv install --keep --debug $PY && \
    pyenv global $PY-debug

# when building uwsgi with the debug version of cpython, be sure to include
# python headers so we can add breakpoints later with gdb when running uwsgi
ENV CFLAGS=-I/root/.pyenv/versions/2.7.17-debug/include/python2.7

# by default we build the current stable release of uwsgi
ARG UWSGI_GIT=unbit/uwsgi@2.0.20
RUN pip install git+https://github.com/$UWSGI_GIT

# For local development, uncomment above two lines and instead install from copied source
# COPY ./uwsgi /src/uwsgi/
# RUN pip install /src/uwsgi

COPY . /app/
WORKDIR /app/

# Ensures that sitecustomize.py will be loaded when Python interpreter is initialized
ENV PYTHONPATH=/app/

EXPOSE 8080

# better gdb frontend
RUN wget -P ~ https://git.io/.gdbinit && pip install pygments

CMD ["./start.sh"]
