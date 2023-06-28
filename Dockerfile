ARG DEBIANVERSION=bullseye

FROM debian:${DEBIANVERSION}-slim as debian-backports-updated

ENV DEBIAN_VERSION=bullseye

RUN echo "# Install packages from ${DEBIAN_VERSION}" && \
    apt-get -y update && \
    apt-get -y install xz-utils && \
    apt-get -y dist-upgrade && \
    echo "deb http://deb.debian.org/debian" ${DEBIAN_VERSION}"-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update

FROM debian-backports-updated as debian-backports-updated-with-s6

ARG S6_OVERLAY_VERSION=3.1.3.0

# S6
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && rm /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && rm /tmp/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && rm /tmp/syslogd-overlay-noarch.tar.xz

FROM debian-backports-updated-with-s6

ENV DEBIAN_VERSION=bullseye

RUN apt install -y postfix && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && \
    cp -rL /etc/hosts /etc/host.conf /etc/localtime /etc/nsswitch.conf /etc/resolv.conf /etc/ssl /var/spool/postfix/etc/

EXPOSE 25

VOLUME ["/etc/postfix", "/var/spool/postfix"]

CMD ["postfix", "start-fg"]

ENTRYPOINT ["/init"]
