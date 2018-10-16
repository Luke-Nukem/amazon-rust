FROM amazonlinux:latest

ARG TOOLCHAIN=stable

RUN yum -y update && \
    yum -y groupinstall "Development Tools" && \
    yum -y install sudo && \
    useradd rust -u 1000 --user-group --create-home --shell /bin/bash --groups wheel

RUN curl https://nodejs.org/download/release/v9.9.0/node-v9.9.0-linux-x64.tar.xz | tar --strip-components 1 -Jx -C /usr/

# Allow sudo without a password.
ADD sudoers /etc/sudoers.d/nopasswd

# Run all further code as user `rust`, and create our working directories
# as the appropriate user.
USER rust
RUN mkdir -p /home/rust/libs /home/rust/src

ENV PATH=/home/rust/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup toolchain install $TOOLCHAIN
# Install clippy - can be used in CI to check a PR/MR is free of common issues
RUN rustup component add clippy-preview
# Install rustfmt - useful in CI for checking PR/MR is correctly formatted
RUN rustup component add rustfmt-preview

# Expect our source code to live in /home/rust/src.  We'll run the build as
# user `rust`, which will be uid 1000, gid 1000 outside the container.
WORKDIR /home/rust/src

