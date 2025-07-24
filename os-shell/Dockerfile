FROM debian:bookworm-slim

ENV SHELL_USER=shell \
    SHELL_PASSWORD=""

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    vim \
    nano \
    git \
    htop \
    tree \
    unzip \
    zip \
    net-tools \
    iputils-ping \
    telnet \
    openssh-server \
    sudo \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r shell --gid=1001 && \
    useradd -r -g shell --uid=1001 --home-dir=/home/shell --shell=/bin/bash shell && \
    mkdir -p /home/shell && \
    chown -R shell:shell /home/shell && \
    echo "shell ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY shell-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/shell-entrypoint.sh

EXPOSE 22
WORKDIR /home/shell

ENTRYPOINT ["shell-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

