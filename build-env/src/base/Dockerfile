FROM debian:12-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update --yes \
    && apt-get install --no-install-recommends --yes \
      autogen \
      automake \
      autopoint \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      flex \
      gawk \
      gettext \
      git \
      jq \
      libtool \
      libncurses5 \
      make \
      nano \
      patch \
      perl \
      pkg-config \
      python3 \
      rsync \
      unzip \
      wget \
      zip \
    && apt-get clean autoclean --yes \
    && apt-get autoremove --yes \
    && rm -rf /etc/ssh/*key*

#
# Where all things get installed (except entrypoint_*.sh scripts)
#
ENV BUILD_ENV=/usr/local/build-env

# Trailing slash: COPY creates ${BUILD_ENV} (upstream created it as a side effect of the JNI header download)
COPY pkg-config-crosswrapper.sh ${BUILD_ENV}/

RUN cd ${BUILD_ENV} \
    && chmod 555 pkg-config-crosswrapper.sh

COPY entrypoint_base.sh /var/opt

WORKDIR /work

ENTRYPOINT ["/var/opt/entrypoint_base.sh"]
