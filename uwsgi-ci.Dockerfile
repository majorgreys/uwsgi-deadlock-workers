# Docker image based on .github/workflows/test.yml
FROM ghcr.io/catthehacker/ubuntu:full-18.04

RUN sudo apt install -qqyf software-properties-common \
    && sudo add-apt-repository ppa:deadsnakes/ppa -y \
    && sudo apt update -qq \
    && sudo apt install --no-install-recommends -qqyf python2.7-dev python3.5-dev python3.6-dev python3.7-dev python3.8-dev \
        python3.8-distutils \
        libpcre3-dev libjansson-dev libcap2-dev \
        curl check

WORKDIR /src/
COPY ./uwsgi/ /src/
COPY ./test.sh /src/
RUN sudo chown -R runner:runner /src/

CMD ["./test.sh"]
