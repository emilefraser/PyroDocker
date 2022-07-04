FROM adoptopenjdk:11-jre-hotspot

# Install mkcert
RUN curl -L -o /usr/local/bin/mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64 \
 && chmod 755 /usr/local/bin/mkcert

ADD run.sh /usr/local/bin/run.sh

ENV CAROOT="/certs" \
    PATH="/usr/local/bin:${PATH}" \
    TRUST_STORES="" \
    JKS_PASSWORD="super-secret" \
    SERVER_HOSTNAMES="docker.for.mac.localhost docker.for.win.localhost localhost localhost.localdomain"

VOLUME /certs
WORKDIR /certs

ENTRYPOINT [ "/usr/local/bin/run.sh" ]
