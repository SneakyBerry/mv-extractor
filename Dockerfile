ARG ARCH=x86_64

FROM quay.io/pypa/manylinux2014_${ARCH} AS builder

WORKDIR /root

# Install build tools
RUN yum update && \
  yum upgrade -y && \
  yum install -y \
    wget \
    unzip \
    cmake \
    git \
    autoconf \
    automake \
    git-core && \
    yum groupinstall 'Development Tools' -y && \
    echo "Installing OpenCV dependencies"

# Install OpenCV
RUN git clone https://github.com/opencv/opencv.git --branch 4.5.5 --depth 1
WORKDIR opencv/build
RUN cmake  \
    -D CMAKE_BUILD_TYPE=RELEASE  \
    -D OPENCV_GENERATE_PKGCONFIG=YES  \
    -D OPENCV_ENABLE_NONFREE=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -D BUILD_SHARED_LIBS=OFF \
    LD_LIST=core,imgproc  \
    ..
RUN make -j$(nproc)
RUN make install
RUN cp ./unix-install/opencv4.pc /usr/local/lib/pkgconfig/
WORKDIR /root

## Install FFMPEG
RUN yum install -y autoconf automake cmake gcc gcc-c++ git libtool make pkgconfig glibc-static
WORKDIR ffmpeg_sources

COPY ./ffmpeg_patch /root/ffmpeg_sources/ffmpeg_patch
ENV FFMPEG_INSTALL_DIR=/root/ffmpeg_sources/FFmpeg
ENV FFMPEG_PATCH_DIR=/root/ffmpeg_sources/ffmpeg_patch

RUN cd ~/ffmpeg_sources && \
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2 && \
    tar xjvf nasm-2.15.05.tar.bz2 && \
    cd nasm-2.15.05 && \
    ./autogen.sh && \
    ./configure --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
    tar xzvf yasm-1.3.0.tar.gz && \
    cd yasm-1.3.0 && \
    ./configure --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    git clone --branch stable --depth 1 https://code.videolan.org/videolan/x264.git && \
    cd x264 && \
    ./configure --disable-shared --enable-static --enable-pic && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
    tar xzvf lame-3.100.tar.gz && \
    cd lame-3.100 && \
    ./configure --enable-nasm && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz && \
    tar xzvf opus-1.3.1.tar.gz && \
    cd opus-1.3.1 && \
    ./configure && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    ./configure --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm --enable-pic --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    wget https://yer.dl.sourceforge.net/project/freetype/freetype2/2.13.2/freetype-2.13.2.tar.xz && \
    tar xvf freetype-2.13.2.tar.xz && \
    cd freetype-2.13.2 && \
    ./autogen.sh && \
    ./configure --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    wget https://yer.dl.sourceforge.net/project/libpng/libpng15/1.5.30/libpng-1.5.30.tar.xz && \
    tar xvf libpng-1.5.30.tar.xz && \
    cd libpng-1.5.30 && \
    ./autogen.sh && \
    ./configure --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    wget https://github.com/madler/zlib/releases/download/v1.3/zlib-1.3.tar.gz && \
    tar xvf zlib-1.3.tar.gz && \
    cd zlib-1.3 && \
    ./configure && \
    make -j$(nproc) libz.a && \
    make install

RUN cd ~/ffmpeg_sources && \
    git clone --depth 1 https://github.com/gcp/libogg.git && \
    cd libogg && \
    ./autogen.sh && \
    ./configure  && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    wget https://github.com/xiph/vorbis/releases/download/v1.3.7/libvorbis-1.3.7.tar.gz && \
    tar xvf libvorbis-1.3.7.tar.gz && \
    cd libvorbis-1.3.7 && \
    ./autogen.sh && \
    ./configure && \
    make -j$(nproc) && \
    make install

RUN cd ~/ffmpeg_sources && \
    git clone https://github.com/FFmpeg/FFmpeg.git --branch n4.1.3 --depth 1 && \
    cd FFmpeg && \
    /root/ffmpeg_sources/ffmpeg_patch/patch.sh && \
    ./configure \
    --pkg-config-flags="--static" \
    --extra-cflags="-I/usr/local/include -static" \
    --extra-ldflags="-L/usr/local/lib -static -static-libgcc -static-libstdc++" \
    --extra-libs="-lpthread -lm" \
    --enable-static \
    --disable-shared \
    --enable-gpl \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-nonfree \
    --enable-pic || cat ffbuild/config.log && \
    make -j$(nproc) && \
    make install
