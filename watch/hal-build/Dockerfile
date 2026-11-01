# Android 9 (Pie) hybris-hal build environment for the skipjack Sailfish port.
FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      bc bison build-essential ca-certificates ccache cpio curl flex g++-multilib \
      gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32z1-dev \
      libc6-dev-i386 libgl1-mesa-dev liblz4-tool libncurses5 libncurses5-dev \
      libssl-dev libx11-dev libxml2-utils lzop openjdk-8-jdk python python3 \
      rsync schedtool squashfs-tools unzip x11proto-core-dev xsltproc zip zlib1g-dev \
      locales sudo \
 && locale-gen en_US.UTF-8 && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID builder && useradd -m -u $UID -g $GID builder \
 && echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder
USER builder
WORKDIR /src
