FROM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS build-base

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=cache,id="apk-${TARGETARCH}${TARGETVARIANT}",sharing=locked,target=/var/cache/apk \
  apk update && \
  apk upgrade --available && \
  apk add \
    autoconf=2.72-r1 \
    automake=1.18.1-r0 \
    build-base=0.5-r3 \
    cmake=4.1.3-r0 \
    curl=8.17.0-r1 \
    g++=15.2.0-r2 \
    gcc=15.2.0-r2 \
    libjpeg-turbo-dev=3.1.2-r0 \
    libpng-dev=1.6.54-r0 \
    make=4.4.1-r3 \
    musl-dev=1.2.5-r21 \
    pkgconf=2.5.1-r0 \
    zlib-dev=1.3.1-r2

#######################################################################################################################
FROM build-base AS build-pngcrush

WORKDIR /usr/src

RUN curl --fail --location --silent --show-error --output pngcrush.tar.gz https://github.com/glennrp/pmt/archive/refs/tags/v1.8.12.tar.gz && \
  tar -xvzf pngcrush.tar.gz --strip-components=1 && \
  make -j"$(nproc)"

#######################################################################################################################
FROM build-base AS build-optipng

ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /usr/src

RUN curl --fail --location --silent --show-error --output optipng.tar.gz https://sourceforge.net/projects/optipng/files/OptiPNG/optipng-7.9.1/optipng-7.9.1.tar.gz/download && \
  tar -xvzf optipng.tar.gz --strip-components=1

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-optipng",sharing=locked,target=/usr/build \
  cmake -S /usr/src -B /usr/build

WORKDIR /usr/build

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-optipng",sharing=locked,target=/usr/build \
  make -j"$(nproc)" && \
  make install

#######################################################################################################################
FROM build-base AS build-advpng

WORKDIR /usr/src

RUN curl --fail --location --silent --show-error --output advpng.tar.gz https://github.com/amadvance/advancecomp/archive/refs/tags/v2.6.tar.gz && \
  tar -xvzf advpng.tar.gz --strip-components=1 && \
  autoreconf -ivf && \
  ./configure && \
  make -j"$(nproc)" && \
  make install

#######################################################################################################################
FROM build-base AS build-jpegoptim

ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /usr/src

RUN curl --fail --location --silent --show-error --output jpegoptim.tar.gz https://github.com/tjko/jpegoptim/archive/refs/tags/v1.5.6.tar.gz && \
  tar -xvzf jpegoptim.tar.gz --strip-components=1

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-jpegoptim",sharing=locked,target=/usr/build \
  cmake -DUSE_MOZJPEG=0 -S /usr/src -B /usr/build

WORKDIR /usr/build

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-jpegoptim",sharing=locked,target=/usr/build \
  make -j"$(nproc)" install

#######################################################################################################################
FROM build-base AS build-guetzli

WORKDIR /usr/src
RUN curl --fail --location --silent --show-error --output guetzli.tar.gz https://github.com/google/guetzli/archive/refs/tags/v1.0.1.tar.gz && \
  tar -xvzf guetzli.tar.gz --strip-components=1 && \
  make -j"$(nproc)"

#######################################################################################################################
FROM build-base AS build-mozjpeg

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=cache,id="apk-${TARGETARCH}${TARGETVARIANT}-mozjpeg",sharing=locked,target=/var/cache/apk \
  apk add nasm=2.16.03-r0

WORKDIR /usr/src

RUN curl --fail --location --silent --show-error --output mozjpeg.tar.gz https://github.com/mozilla/mozjpeg/archive/refs/tags/v4.1.1.tar.gz && \
  tar -xvzf mozjpeg.tar.gz --strip-components=1

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-mozjpeg",sharing=locked,target=/usr/build \
  cmake -G"Unix Makefiles" -DENABLE_STATIC=FALSE -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S /usr/src -B /usr/build

WORKDIR /usr/build

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-mozjpeg",sharing=locked,target=/usr/build \
  make -j"$(nproc)" install

#######################################################################################################################
FROM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS release

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=cache,id="apk-${TARGETARCH}${TARGETVARIANT}",sharing=locked,target=/var/cache/apk \
  apk update && \
  apk upgrade --available && \
  apk add \
    libjpeg-turbo=3.1.2-r0 \
    libpng=1.6.54-r0 \
    libstdc++=15.2.0-r2 \
    zlib=1.3.1-r2

COPY --from=build-pngcrush --chmod=0755 /usr/src/pngcrush /usr/local/bin/

COPY --from=build-optipng --chmod=0755 /usr/local/bin/optipng /usr/local/bin/
COPY --from=build-optipng /usr/local/lib/*.so /usr/local/lib/*.so.* /usr/local/lib/

COPY --from=build-advpng --chmod=0755 /usr/local/bin/advpng /usr/local/bin/

COPY --from=build-jpegoptim --chmod=0755 /usr/local/bin/jpegoptim /usr/local/bin/

COPY --from=build-guetzli --chmod=0755 /usr/src/bin/Release/guetzli /usr/local/bin/

COPY --from=build-mozjpeg --chmod=0755 /opt/mozjpeg/bin/* /usr/local/bin/
COPY --from=build-mozjpeg /opt/mozjpeg/lib64/*.so /opt/mozjpeg/lib64/*.so.* /usr/local/lib/

WORKDIR /app
