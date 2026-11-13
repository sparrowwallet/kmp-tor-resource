FROM ghcr.io/sparrowwallet/build-env.base:latest

RUN apt-get install --no-install-recommends --yes \
      gcc-mingw-w64-base \
      mingw-w64-common \
      mingw-w64-tools \
    && apt-get clean autoclean --yes \
    && apt-get autoremove --yes
