FROM alpine

# Enable HTTPS support in wget and set nsswitch.conf to make resolution work within containers
RUN apk add --no-cache --update openssl \
  && echo hosts: files dns > /etc/nsswitch.conf

# Download Nix and install it into the system.
ARG NIX_VERSION=2.3.14
RUN wget https://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz \
  && tar xf nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz \
  && addgroup -g 30000 -S nixbld \
  && for i in $(seq 1 30); do adduser -S -D -h /var/empty -g "Nix build user $i" -u $((30000 + i)) -G nixbld nixbld$i ; done \
  && mkdir -m 0755 /etc/nix \
  && echo 'sandbox = false' > /etc/nix/nix.conf \
  && mkdir -m 0755 /nix && USER=root sh nix-${NIX_VERSION}-$(uname -m)-linux/install \
  && ln -s /nix/var/nix/profiles/default/etc/profile.d/nix.sh /etc/profile.d/ \
  && rm -r /nix-${NIX_VERSION}-$(uname -m)-linux* \
  && rm -rf /var/cache/apk/* \
  && /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-old \
  && /nix/var/nix/profiles/default/bin/nix-store --optimise \
  && /nix/var/nix/profiles/default/bin/nix-store --verify --check-contents

ONBUILD ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels

RUN apk update && \
    set -ex && \
    apk --no-cache add curl jq bc bzip2 git sudo bash && \
    echo 'sandbox = false' > /etc/nix/nix.conf && \
    adduser maker --home /home/maker --disabled-password --gecos "" --shell /bin/sh && \
    echo "maker ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/maker &&\
    chmod 0440 /etc/sudoers.d/maker && \
    chown -R maker /nix

RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
    
USER maker
ENV USER maker
WORKDIR /home/maker


RUN touch .bash_profile \
 && sudo curl https://dapp.tools/install | sh

RUN nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_6_12
RUN sudo apk add --no-cache python3 py3-pip
RUN pip install web3

RUN mkdir -p /home/maker/dss
WORKDIR /home/maker/dss
ADD . /home/maker/dss

RUN sudo chmod -R 777 /home/maker
ARG NEON_PROXY_URL
ARG NEON_ACCOUNTS

ENV NEON_PROXY_URL=${NEON_PROXY_URL}
ENV NEON_ACCOUNTS=${NEON_ACCOUNTS}
ENTRYPOINT ["/bin/bash", "-l", "./start.sh"]
