
FROM lambci/lambda:build-ruby2.7


ARG PROXY=http://proxy:3128
ARG PROXY_HOST=proxy:3128


RUN export HTTP_PROXY=$PROXY
RUN export http_proxy=$PROXY
RUN echo proxy=$PROXY >> /etc/yum.conf
RUN echo proxy=$PROXY >> "$HOME/.curlrc"
RUN echo export http_proxy=  $PROXY >> "$HOME/.bashrc"
RUN echo export HTTP_PROXY=  $PROXY >> "$HOME/.bashrc"
RUN echo export https_proxy= $PROXY >> "$HOME/.bashrc"
RUN echo export HTTPS_PROXY= $PROXY >> "$HOME/.bashrc"
RUN echo [http_proxy] >> "$HOME/.hgrc"
RUN echo host = $PROXY_HOST >> "$HOME/.hgrc"
RUN echo always = true >> "$HOME/.hgrc"
RUN echo HTTP_PROXY: $PROXY >> "$HOME/.gemrc"
RUN echo http_proxy: $PROXY >> "$HOME/.gemrc"




RUN git config --global http.proxy $PROXY

RUN gem install bundler -p $PROXY

WORKDIR /var/task
RUN export TASK=/var/task

RUN mkdir ffmpeg_sources
RUN mkdir ffmpeg_dist
RUN mkdir bin

RUN yum install autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel -y
RUN yum install -y libpng-devel

WORKDIR /var/task/ffmpeg_sources
RUN curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
RUN tar xjvf nasm-2.14.02.tar.bz2
WORKDIR nasm-2.14.02
RUN ./autogen.sh
RUN ./configure --prefix="$TASK/ffmpeg_build" --bindir="$TASK/bin"
RUN make
RUN make install
RUN 
WORKDIR /var/task/ffmpeg_sources
RUN curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
RUN tar xzvf yasm-1.3.0.tar.gz
WORKDIR yasm-1.3.0
RUN ./configure --prefix="$TASK/ffmpeg_build" --bindir="$TASK/bin"
RUN make
RUN make install

WORKDIR /var/task/ffmpeg_sources
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git
WORKDIR x264
RUN PKG_CONFIG_PATH="$TASK/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$TASK/ffmpeg_build" --bindir="$TASK/bin" --enable-static
RUN make
RUN make install


WORKDIR /var/task/ffmpeg_sources
RUN git clone https://bitbucket.org/multicoreware/x265_git.git
WORKDIR /var/task/ffmpeg_sources/x265_git/source
RUN cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TASK/ffmpeg_build" -DENABLE_SHARED:bool=off .
RUN make
RUN make install

WORKDIR /var/task/ffmpeg_sources
RUN git clone --depth 1 https://github.com/mstorsjo/fdk-aac
WORKDIR fdk-aac
RUN autoreconf -fiv
RUN ./configure --prefix="$TASK/ffmpeg_build" --disable-shared
RUN make
RUN make install

WORKDIR /var/task/ffmpeg_sources
RUN curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
RUN tar xzvf lame-3.100.tar.gz
WORKDIR lame-3.100
RUN ./configure --prefix="$TASK/ffmpeg_build" --bindir="$TASK/bin" --disable-shared --enable-nasm
RUN make
RUN make install

WORKDIR /var/task/ffmpeg_sources
RUN curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz
RUN tar xzvf opus-1.3.1.tar.gz
WORKDIR opus-1.3.1
RUN ./configure --prefix="$TASK/ffmpeg_build" --disable-shared
RUN make
RUN make install

WORKDIR /var/task/ffmpeg_sources
RUN git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
WORKDIR libvpx
RUN ./configure --prefix="$TASK/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
RUN make
RUN make install

WORKDIR /var/task/ffmpeg_sources
RUN curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
RUN tar xjvf ffmpeg-snapshot.tar.bz2
WORKDIR ffmpeg
RUN PATH="$TASK/bin:$PATH" PKG_CONFIG_PATH="$TASK/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$TASK/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$TASK/ffmpeg_build/include" \
  --extra-ldflags="-L$TASK/ffmpeg_build/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir=../../ffmpeg_dist \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
RUN make
RUN make install

RUN chmod -R a+x ../../ffmpeg_dist 
RUN mkdir /var/task/dist
RUN cp -r ../../ffmpeg_dist/* /var/task/dist


RUN yum install -y yum-utils rpmdevtools
WORKDIR /tmp
RUN yumdownloader unixODBC.x86_64 libtool-ltdl.x86_64 gnutls.x86_64 \
  bzip2-libs.x86_64 freetype.x86_64 libpng.x86_64
RUN rpmdev-extract *rpm
RUN cp /tmp/*/usr/lib64/* /var/task/dist



WORKDIR /var/task/dist

COPY . .

RUN bundle config set --local path 'vendor/bundle'
RUN bundle install


RUN zip -r dist.zip .

RUN mkdir /var/task/output
CMD cp dist.zip /var/task/output