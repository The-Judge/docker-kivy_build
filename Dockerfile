FROM python:3.8.6
MAINTAINER Marc Richter <mail@marc-richter.info>

ENV NDK_VERSION="r19c"
ENV SDK_VERSION="6514223_latest"
ENV ANT_VERSION="1.9.4"
ENV ANDROID_SDK_LICENSES_DIR="/root/.buildozer/android/platform/android-sdk/licenses"
ARG DEBIAN_FRONTEND="noninteractive"
ARG NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip"
ARG SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-${SDK_VERSION}.zip"
ARG ANT_URL="http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz"

RUN dpkg --add-architecture i386
RUN apt-get update

RUN apt-get install -y \
        apt-utils \
        software-properties-common \
        build-essential \
        ccache \
        curl \
        git \
        rsync \
        pkg-config \
        lld \
        zlib1g-dev \
        libncurses5:i386 \
        libstdc++6:i386 \
        zlib1g:i386

# Activate ccache
RUN echo 'export PATH="/usr/lib/ccache:$PATH"' >> /etc/profile.d/ccache.sh
RUN echo 'mkdir -p /app/build/.ccache && export CCACHE_DIR=/app/build/.ccache' >> /etc/profile.d/ccache.sh
RUN echo '. /etc/profile' >> /root/.profile

# Kivy build deps - https://bit.ly/3oO0cSY
RUN apt-get install -y \
        libgl1-mesa-dev \
        libgles2-mesa-dev \
        libgstreamer1.0-dev \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-omx \
        gstreamer1.0-alsa \
        libmtdev-dev \
        xclip \
        xsel \
        libjpeg-dev

# Install Kivy
RUN python -m pip install --upgrade \
        pyinstaller \
        setuptools \
        virtualenv \
        kivy[full] \
        kivy_examples

# Install buildozer dependencies - https://bit.ly/2IKhv81
RUN apt-get install -y \
        git \
        zip \
        unzip \
        python3-pip \
        autoconf \
        libtool \
        pkg-config \
        zlib1g-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libtinfo5 \
        cmake \
        libffi-dev \
        libssl-dev \
        ant
# Install openjdk-8-jdk from adoptopenjdk, since it got removed from Debian
RUN curl --silent https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - && \
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ && \
    apt-get update && \
    apt-get install -y adoptopenjdk-8-hotspot
RUN python -m pip install --upgrade \
        cython \
        virtualenv \
        pipenv
# Install buildozer from source
RUN git clone https://github.com/kivy/buildozer.git && \
    cd buildozer && \
    python setup.py install && \
    cd .. && \
    rm -rf buildozer

# Pre-fetch Android SDK/NDK and ANT
RUN mkdir -p /usr/share/android/ndk /usr/share/android/sdk /usr/share/android/ant /usr/share/android/p4a
# Pre-fetch NDK
WORKDIR /tmp
RUN curl --silent -o android-ndk-${NDK_VERSION}-linux-x86_64.zip ${NDK_URL} && \
    unzip android-ndk-${NDK_VERSION}-linux-x86_64.zip && \
    rm -f android-ndk-${NDK_VERSION}-linux-x86_64.zip && \
    mv -fv android-ndk-${NDK_VERSION}/* /usr/share/android/ndk/ && \
    rm -rfv android-ndk-${NDK_VERSION}
# Pre-fetch SDK
WORKDIR /usr/share/android/sdk
RUN curl --silent -o commandlinetools-linux-${SDK_VERSION}.zip ${SDK_URL} && \
    unzip commandlinetools-linux-${SDK_VERSION}.zip && \
    rm -f commandlinetools-linux-${SDK_VERSION}.zip
# Pre-fetch ANT
WORKDIR /tmp
RUN curl --silent ${ANT_URL} | tar zxvf - && \
    mv apache-ant-${ANT_VERSION}/* /usr/share/android/ant && \
    rm -rfv apache-ant-${ANT_VERSION}
# Pre-fetch p4a sources
WORKDIR /usr/share/android/p4a
RUN git clone -b master --single-branch https://github.com/kivy/python-for-android.git .

WORKDIR /

ADD build.sh /root/build.sh
ADD prepare_env.sh /root/prepare_env.sh
RUN chmod 755 /root/build.sh /root/prepare_env.sh

WORKDIR /app
