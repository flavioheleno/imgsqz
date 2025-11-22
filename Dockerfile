FROM alpine:3.22.2@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412 AS build-base

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=cache,id="apk-${TARGETARCH}${TARGETVARIANT}",sharing=locked,target=/var/cache/apk \
  apk update && \
  apk upgrade --available && \
  apk add \
    autoconf=2.72-r1 \
    automake=1.17-r1 \
    build-base=0.5-r3 \
    cmake=3.31.7-r1 \
    curl=8.14.1-r2 \
    g++=14.2.0-r6 \
    gcc=14.2.0-r6 \
    libjpeg-turbo-dev=3.1.0-r0 \
    libpng-dev=1.6.47-r0 \
    make=4.4.1-r3 \
    musl-dev=1.2.5-r10 \
    pkgconf=2.4.3-r0 \
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
  cmake -G"Unix Makefiles" -DENABLE_STATIC=FALSE -S /usr/src -B /usr/build

WORKDIR /usr/build

RUN --mount=type=cache,id="build-${TARGETARCH}${TARGETVARIANT}-mozjpeg",sharing=locked,target=/usr/build \
  make -j"$(nproc)" install

#######################################################################################################################
FROM alpine:3.22.2@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412 AS release

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=cache,id="apk-${TARGETARCH}${TARGETVARIANT}",sharing=locked,target=/var/cache/apk \
  apk update && \
  apk upgrade --available && \
  apk add \
    libjpeg-turbo=3.1.0-r0 \
    libpng=1.6.47-r0 \
    libstdc++=14.2.0-r6 \
    zlib=1.3.1-r2

COPY --from=build-pngcrush --chmod=0755 /usr/src/pngcrush /usr/local/bin/

COPY --from=build-optipng --chmod=0755 /usr/local/bin/optipng /usr/local/bin/
COPY --from=build-optipng /usr/local/lib/*.so /usr/local/lib/*.so.* /usr/local/lib/

COPY --from=build-jpegoptim --chmod=0755 /usr/local/bin/jpegoptim /usr/local/bin/

COPY --from=build-guetzli --chmod=0755 /usr/src/bin/Release/guetzli /usr/local/bin/

COPY --from=build-mozjpeg --chmod=0755 /opt/mozjpeg/bin/* /usr/local/bin/
COPY --from=build-mozjpeg /opt/mozjpeg/lib64/*.so /opt/mozjpeg/lib64/*.so.* /usr/local/lib/

WORKDIR /app
