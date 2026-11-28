# ==============================================================================
#  RetroOS Shell - Containerized Environment
# ==============================================================================
FROM ubuntu:22.04

LABEL maintainer="Md Showkotul Islam <mdshowkotulislam32@gmail.com>"
LABEL description="RetroOS Shell: Interactive Unix Shell & Operating Systems Laboratory"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    procps \
    coreutils \
    gawk \
    grep \
    sed \
    util-linux \
    strace \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app

RUN chmod +x retroos.sh test/test_all.sh

ENTRYPOINT ["bash", "retroos.sh"]
