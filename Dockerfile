FROM alpine:latest AS builder
WORKDIR /tmp
ENV BUILD_DIR=/tmp/build
RUN apk update \
    && apk upgrade \
    && apk --no-cache add \
    autoconf \
    automake \
    bash \
    binutils-dev \
    build-base \
    git \
    libedit-dev \
    libedit-static \
    linux-headers \
    musl-dev \
    ncurses-dev \
    ncurses-static \
    upx \
    zlib-dev \
    zlib-static

SHELL ["bash","-c"]
# build rootfs
RUN mkdir -p "${BUILD_DIR}"

# Build static OpenSSL libraries
RUN git clone https://github.com/openssl/openssl.git \
    &&  cd openssl/ \
    && ./config \
        --static \
        -static \
    && make install \
    && cd ../

# Build static OpenSSH
RUN git clone https://github.com/openssh/openssh-portable \
    && cd openssh-portable \
    && autoreconf \
    && export LIBS="/lib/libz.a /usr/local/lib/libcrypto.a /usr/lib/libedit.a /usr/lib/libncursesw.a" \
    && ./configure \
        --prefix=${BUILD_DIR} \
        --bindir=${BUILD_DIR}/bin \
        --libexecdir=${BUILD_DIR}/usr/local/libexec \
        --sysconfdir=${BUILD_DIR}/etc/ssh \
        --with-libedit \
        --with-4in6 \
        --without-shadow \
        --with-ldflags=-static \
    && make install \
    && cd ../

# cleanup
RUN rm -rf ${BUILD_DIR}/share || true \
    # compress all binaries with upx
    # find is cool, and will recursively search the whole file tree
    # find *only* the binary executable files, and then compress them
    # with upx
    && find /tmp/build/ -type f -executable -size +40k -exec upx --lzma {} \;

FROM scratch
WORKDIR /
COPY --from=builder /tmp/build ./
CMD ["sshd", "-h"]