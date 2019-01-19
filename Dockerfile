FROM lambci/lambda:build-nodejs8.10

ARG TOOLCHAIN=stable

# Install minimum dev environment for our purposes
# rather than the old groupinstall "Development"
RUN \
 yum -y install \
 binutils shadow-utils sudo \
 autoconf automake elfutils git gdb make cmake gcc gcc-c++ patch pkgconfig \
 bzip2 tar unzip xz zip && \
 useradd rust -u 1000 --user-group --create-home --shell /bin/bash --groups wheel

# install fixuid
RUN USER=rust && \
    GROUP=wheel && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.1/fixuid-0.1-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml
ENTRYPOINT ["fixuid"]

# Allow sudo without a password.
ADD sudoers /etc/sudoers.d/nopasswd

# Run all further code as user `rust`, and create our working directories
# as the appropriate user.
USER rust
RUN mkdir -p /home/rust/libs /home/rust/src

ENV PATH=/var/lang/bin:/opt/bin:/home/rust/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup toolchain install $TOOLCHAIN
RUN rustup component add clippy-preview
RUN rustup component add rustfmt-preview

# Expect our source code to live in /home/rust/src.  We'll run the build as
# user `rust`, which will be uid 1000, gid 1000 outside the container.
WORKDIR /home/rust/src
