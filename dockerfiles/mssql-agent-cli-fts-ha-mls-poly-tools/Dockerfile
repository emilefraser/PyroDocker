# Base OS layer: Latest Ubuntu LTS
FROM mcr.microsoft.com/mssql/server:2019-latest

USER root

# Install prerequistes since it is needed to get repo config for SQL server
RUN apt-get update && \
    apt-get install -y \
    			   apt-transport-https \
    			   apt-utils \
    			   build-essential \
    			   bzip2 \ 
                   curl \
                   debconf-utils \                  
                   fakechroot \
                   gcc \
                   iptables \                                   
                   libnuma-dev \
                   libsss-nss-idmap-dev \
                   locales \
                   make \                 
                   m4 \                   
                   tzdata \                   
                   software-properties-common \
                   sudo \
                   supervisor \
                   wget \
                   unzip \
                   zip 
                
# Install mssql-cli
#RUN apt-get install -y mssql-cli -y                                   
                  
# Install additional mssql packages
RUN add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)" && \
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-preview.list)" && \
    apt update && \
    apt-get install -y mssql-server-fts && \
    apt-get install -y mssql-server-ha  && \
    apt-get install -y mssql-server-polybase

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 1433

USER mssql

# Run SQL Server process
CMD ["/opt/mssql/bin/sqlservr"]
