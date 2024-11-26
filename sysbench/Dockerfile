FROM centos:8

# Use vault repositories to access archived CentOS 8 packages
RUN sed -i 's|mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Install required dependencies
RUN yum -y install epel-release

RUN \
  yum -y install \
        wget \
        tar \
        gcc \
        make \
        mariadb-devel \
        openssl-devel \
        libaio-devel \
        tar git autoconf automake libtool

# Download and build Sysbench from source
RUN git clone https://github.com/akopytov/sysbench.git && \
    cd sysbench && \
    ./autogen.sh && \
    ./configure --with-mysql --with-openssl && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf sysbench

# Set up working directory
WORKDIR /sysbench-scripts

# Keep the container running by default
CMD ["sleep", "infinity"]
