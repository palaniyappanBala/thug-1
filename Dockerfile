# This is a Dockerfile for creating a Thug https://github.com/buffer/thug Container from the latest
# Ubuntu base image. This is known bo be working on Ubuntu 14.04. It should work on any later version
# This is a full installation of Thug including all optional packages used for distributed operation
FROM ubuntu:latest
MAINTAINER ali@ikinci.info
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV V8_HOME /opt/v8/
WORKDIR  /opt
COPY get-pip.py /opt/
COPY requirements.txt /opt/
COPY pyv8_r586.tar.bz2 /opt/
COPY v8_r19632.tar.bz2 /opt/
COPY checkinstall.py /opt/
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install --no-install-recommends \
      build-essential \
      curl \
      dh-autoreconf \
      git \
      graphviz \
      graphviz-dev \
      gyp \
      libboost-dev \
      libboost-python-dev \
      libboost-python1.54.0 \
      libboost-system-dev \
      libboost-system1.54.0 \
      libboost-thread-dev \
      libboost-thread1.54.0 \
      libemu-dev \
      libemu2 \
      libffi-dev \
      libfuzzy-dev \
      libpcre3 \
      libpcre3-dev \
      librabbitmq1 \
      libtool \
      libxml2-dev \
      libxslt1-dev \
      pkg-config \
      python \
      python-dev \
      ssdeep \
      subversion \
      zlib1g-dev && \
    python /opt/get-pip.py && \
    pip install -r /opt/requirements.txt && \

    # libemu
    git clone https://github.com/buffer/pylibemu.git pylibemu && \
    cd  /opt/pylibemu && \
    python setup.py build && \
    python setup.py install && \
    cd  /opt && \
    curl -LO https://github.com/plusvic/yara/archive/v3.4.0.tar.gz && \
    tar xvfz v3.4.0.tar.gz && \
    cd  /opt/yara-3.4.0/ && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    make install && \
    cd  /opt/yara-3.4.0/yara-python/ && \
    python setup.py build && \
    python setup.py install && \
    cd /opt && \

    # thug
    git clone https://github.com/buffer/thug.git /opt/thug && \
    # disable mongodb
    sed -i '/^[[:blank:]]*\[mongodb\]$/{n;s/True/False/g;}' /opt/thug/src/Logging/logging.conf && \
    # disable elasticsearch
    sed -i '/^[[:blank:]]*\[elasticsearch\]$/{n;s/True/False/g;}' /opt/thug/src/Logging/logging.conf && \
    # disable hpfeeds
    sed -i '/^[[:blank:]]*\[hpfeeds\]$/{n;s/True/False/g;}' /opt/thug/src/Logging/logging.conf && \

    # PyV8 and V8
    tar xvfj pyv8_r586.tar.bz2 && \
    tar xvfj v8_r19632.tar.bz2 && \
    patch -d /opt/ -p0 <  /opt/thug/patches/PyV8-patch1.diff && \
    patch -d /opt/v8/ -p1 < /opt/thug/patches/V8-patch1.diff && \
    cd  /opt/pyv8/ && \
    python setup.py build && \
    python setup.py install && \
    cd  /opt && \
    echo "/usr/local/lib" >> /etc/ld.so.conf && \
    rm -rfv /var/lib/apt/lists/* pyv8_r586.tar.bz2 v3.4.0.tar.gz v8_r19632.tar.bz2 pylibemu pyv8 v8 get-pip.py requirements.txt install.sh /var/lib/man-db /opt/yara-3.4.0/ && \
    apt-get -y remove \
      build-essential \
      curl \
      dh-autoreconf \
      git \
      graphviz-dev \
      gyp \
      libboost-dev \
      libboost-python-dev \
      libboost-system-dev \
      libboost-thread-dev \
      libemu-dev \
      libffi-dev \
      libfuzzy-dev \
      libpcre3-dev \
      libtool \
      pkg-config \
      python-dev \
      subversion \
      zlib1g-dev && \
	 	apt-get clean && apt-get autoclean && \
		apt-get -y autoremove && \
		dpkg -l |grep ^rc |awk '{print $2}' |xargs dpkg --purge && \
	 	rm -f /opt/thug/samples/exploits/blackhole.html && \
    ldconfig && \
    python /opt/checkinstall.py && \
    python /opt/thug/src/thug.py
