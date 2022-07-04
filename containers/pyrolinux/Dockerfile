# Sets the base image for subsequent
FROM alpine:latest

#Defines a variable that users can pass at build-time to the builder using --build-arg
#ARG WORKROOT="C:/env/docker/pyroos"

#Copy new files, dirctories, or remote file URLs from into the filesystem of the container
#The ADD instruction copies new files, directories or remote file URLs from <src> and adds them to the filesystem of the image at the path <dest>.
#ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz
#ADD hom* /mydir/

#Sets an environment variable
#ENV <key>=<value>
#ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

### RUN ###
# Execute commands in a new layer on top of the current image and commit the results
# Updgrade and Update apk
RUN apk update && \
    apk upgrade

RUN apk add --no-cache bash coreutils grep sed    

## Add Distros
RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache

RUN apk add --no-cache \
    ca-certificates \
    less \
    curl \
    libgcc \
    libintl

RUN apk add sudo \
    shadow

RUN apk add vim
# RUN ["/bin/bash", "-c", "echo hello"]

RUN echo root:105022 | chpasswd

# Informs container runtime that the container listens on the specified network ports at runtime
#EXPOSE 80/tcp
#EXPOSE 80/udp

#Copy new files or directories into the filesystem of the container
# not for urls
#COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]
# COPY test.txt /absoluteDir/

#Creates a mount point and marks it as holding externally mounted volumes from native host or other containers
# VOLUME ["/data"]

#Sets the username or UID to use when running the image
USER root:root
#USER <UID>[:<GID>]

#Informs container runtime that the container listens on the specified network ports at runtime
LABEL "author"="Emile Fraser"
LABEL "email"="efraser25@gmail.com"
LABEL "imagename"="pyroalpine"
LABEL "version"="1.0"
#LABEL description="This text illustrates \

#Sets the working directory for any RUN, CMD, ENTRYPOINT, COPY, and ADD commands
# WORKDIR ${FOO}
# WORKDIR /path/to/workdir

#Adds an instruction to be executed later, when the image is used as the base for another build
#ONBUILD ADD . /app/src
#ONBUILD RUN /usr/local/bin/python-build --dir /app/src

# Allowed only once (if many then last one takes effect)
CMD [ "/bin/bash" ]

#Allows you to configure a container that will run as an executable
#ENTRYPOINT ["executable", "param1", "param2"]
#ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
ENTRYPOINT ["tail", "-f", "/dev/null"]

SHELL ["/bin/bash", "--login", "-c"]

# Sets the system call signal that will be sent to the container to exit
#STOPSIGNAL signal














