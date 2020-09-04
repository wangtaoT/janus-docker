FROM debian:buster-slim AS janus

RUN sed -i s@/deb.debian.org/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list && \
    sed -i s@/security.debian.org/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list && \
    apt-get -y update && \
	apt-get install -y \
		libmicrohttpd-dev \
		libjansson-dev \
		libssl-dev \
		libsofia-sip-ua-dev \
		libglib2.0-dev \
		libopus-dev \
		libogg-dev \
		libcurl4-openssl-dev \
		liblua5.3-dev \
		libconfig-dev \
		libusrsctp-dev \
		libwebsockets-dev \
		libnanomsg-dev \
		librabbitmq-dev \
		pkg-config \
		gengetopt \
		libtool \
		automake \
		build-essential \
		wget \
		git \
		gtk-doc-tools && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
	wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz && \
	tar xfv v2.3.0.tar.gz && \
	cd libsrtp-2.3.0 && \
	./configure --prefix=/usr --enable-openssl && \
	make shared_library && \
	make install

RUN cd /tmp && \
	git clone https://gitlab.freedesktop.org/libnice/libnice && \
	cd libnice && \
	git checkout 0.1.17 && \
	./autogen.sh && \
	./configure --prefix=/usr && \
	make && \
	make install

RUN cd /tmp && git clone --depth=1 --branch v0.10.3 https://github.com/meetecho/janus-gateway.git janus
RUN cd /tmp/janus && \
	sh autogen.sh && \
	./configure --prefix=/opt/janus && \
	make && \
	make install && \
	make configs

FROM debian:buster-slim

RUN sed -i s@/deb.debian.org/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list && \
    sed -i s@/security.debian.org/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list && \
    apt-get -y update && \
	apt-get install -y libmicrohttpd12 libjansson4 libssl1.1 libsofia-sip-ua0 \ 
        libglib2.0-0 libopus0 libogg0 libcurl4 liblua5.3-0 libconfig9 libusrsctp1 \
		libwebsockets8 libnanomsg5 librabbitmq4 supervisor procps &&\
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY --from=janus /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so.1
COPY --from=janus /usr/lib/libnice.la /usr/lib/libnice.la
COPY --from=janus /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so.10.10.0
COPY --from=janus /opt/janus /opt/janus

COPY docker-conf /opt/conf

RUN ln -s /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so && \
    ln -s /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so.10 && \
    ln -s /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so && \
    rm -rf /opt/janus/etc/janus && ln -s /opt/conf/janus /opt/janus/etc/janus && \
    rm -rf /etc/supervisor/conf.d && ln -s /opt/conf/supervisor /etc/supervisor/conf.d


EXPOSE 7088 7089 8000 8088 8089 8889
EXPOSE 10000-10200/udp

CMD ["supervisord", "-n"]
