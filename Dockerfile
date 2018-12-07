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

# Allow sudo without a password.
ADD sudoers /etc/sudoers.d/nopasswd

# Run all further code as user `rust`, and create our working directories
# as the appropriate user.
USER rust
RUN mkdir -p /home/rust/libs /home/rust/src

RUN \
 cd /home/rust && \
 git clone https://github.com/juj/emsdk.git && \
 cd emsdk && \
 ./emsdk install latest && \
 ./emsdk activate latest
RUN echo 'source /home/rust/emsdk/emsdk_env.sh' >> /home/rust/.bashrc

ENV PATH=/home/rust/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup toolchain install $TOOLCHAIN
RUN rustup target add wasm32-unknown-emscripten
RUN rustup component add clippy-preview
RUN rustup component add rustfmt-preview

# Expect our source code to live in /home/rust/src.  We'll run the build as
# user `rust`, which will be uid 1000, gid 1000 outside the container.
WORKDIR /home/rust/src

