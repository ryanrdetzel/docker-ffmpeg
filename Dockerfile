FROM ubuntu

ENV X264_VERSION=20170226-2245-stable \
    X265_VERSION=2.3          \
    FFMPEG_VERSION=2.8.11     \
    FDKAAC_VERSION=0.1.5      \
    LAME_VERSION=3.99.5       \
    SRC=/usr/local

ARG FFMPEG_KEY="D67658D8"

RUN apt-get update
RUN apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev \
  libtheora-dev libtool libvorbis-dev  \
  pkg-config texinfo zlib1g-dev curl yasm cmake git libssl-dev 


## x264 http://www.videolan.org/developers/x264.html
RUN  \
       DIR=$(mktemp -d) && cd ${DIR} && \
       curl -sL https://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
       tar -jx --strip-components=1 && \
       ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-pic --enable-shared --disable-cli && \
       make && \
       make install && \
       rm -rf ${DIR}

RUN  \
DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
        tar -zx && \
        cd x265_${X265_VERSION}/build/linux && \
        ./multilib.sh && \
        make -C 8bit install && \
        rm -rf ${DIR}

RUN  \
## libmp3lame http://lame.sourceforge.net/
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://downloads.sf.net/project/lame/lame/${LAME_VERSION%.*}/lame-${LAME_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --disable-static --enable-nasm --datarootdir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN  \
## fdk-aac https://github.com/mstorsjo/fdk-aac
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${SRC}" --disable-static --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys ${FFMPEG_KEY} && \
        curl -sLO http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
        curl -sLO http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz.asc && \
        gpg --batch  --verify ffmpeg-${FFMPEG_VERSION}.tar.gz.asc ffmpeg-${FFMPEG_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.gz && \
        ./configure \
        --bindir="${SRC}/bin" \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --disable-static \
        --enable-avresample \
        --enable-gpl \
        --enable-libfdk_aac \
        --enable-libmp3lame \
        --enable-libx264 \
        --enable-libx265 \
        --enable-nonfree \
        --enable-openssl \
        --enable-postproc \
        --enable-shared \
        --enable-small \
        --enable-version3 \
        --extra-cflags="-I${SRC}/include" \
        --extra-ldflags="-L${SRC}/lib" \
        --extra-libs=-ldl \
        --prefix="${SRC}" && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${SRC}/bin && \
        rm -rf ${DIR} \
        ldconfig
