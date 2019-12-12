FROM openjdk:8-alpine

RUN apk add --no-cache curl tar bash fontconfig ttf-dejavu git imagemagick graphviz maven \
    nodejs nodejs-npm yarn \
    php7 php7-json php7-phar php7-iconv php7-openssl php7-dom php7-mbstring php7-xml php7-xmlwriter php7-tokenizer \
    python python-dev py-pip \
    musl-dev gcc gnupg git openssh file

RUN npm i -g raml2html
RUN npm install -g npm-cli-login

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN pip install --upgrade pip
RUN pip install requests

COPY settings.xml /root/.m2/settings.xml

COPY download-poom-ci-utilities-pom.xml /tmp/download-poom-ci-utilities-pom.xml
RUN mvn clean install -f /tmp/download-poom-ci-utilities-pom.xml
RUN rm -f /tmp/download-poom-ci-utilities-pom.xml


COPY *.sh /usr/local/bin/
RUN chmod a+x  /usr/local/bin/*.sh

RUN mkdir -p /m2
RUN mkdir -p /src

ENV USER_HOME_DIR="/root"
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV MAVEN_MS "256m"
ENV MAVEN_MX "512m"
ENV MAVEN_OPTS "-Xms$MAVEN_MS -Xmx$MAVEN_MX"

####################
# python3
####################

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# install ca-certificates so that HTTPS works consistently
# other runtime dependencies for Python are installed later
RUN apk add --no-cache ca-certificates

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.7.3

RUN set -ex \
	&& apk add --no-cache --virtual .fetch-deps \
		gnupg \
		tar \
		xz \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& apk add --no-cache --virtual .build-deps  \
		bzip2-dev \
		coreutils \
		dpkg-dev dpkg \
		expat-dev \
		findutils \
		gcc \
		gdbm-dev \
		libc-dev \
		libffi-dev \
		libnsl-dev \
		libtirpc-dev \
		linux-headers \
		make \
		ncurses-dev \
		openssl-dev \
		pax-utils \
		readline-dev \
		sqlite-dev \
		tcl-dev \
		tk \
		tk-dev \
		util-linux-dev \
		xz-dev \
		zlib-dev \
# add build deps before removing fetch deps in case there's overlap
	&& apk del .fetch-deps \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
# set thread stack size to 1MB so we don't segfault before we hit sys.getrecursionlimit()
# https://github.com/alpinelinux/aports/commit/2026e1259422d4e0cf92391ca2d3844356c649d0
		EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
	&& make install \
	\
	&& find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		| xargs -rt apk add --no-cache --virtual .python-rundeps \
	&& apk del .build-deps \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.1

RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

CMD ["python3"]

####################
# hotballoon-shed
####################
ENV HOTBALLOON_SHED_VERSION 1.16.0

RUN mkdir -p /hotballoon-shed
RUN git clone --branch $HOTBALLOON_SHED_VERSION https://github.com/flexiooss/hotballoon-shed.git /hotballoon-shed
RUN bash /hotballoon-shed/venv.sh
RUN bash /hotballoon-shed/hotballoon-shed.sh self-install
RUN bash /hotballoon-shed/hotballoon-shed.sh set-flexio-registry -S /hotballoon-shed
COPY hbshed /usr/local/bin/
RUN chmod a+x  /usr/local/bin/hbshed

####################
# flexio-flow
####################
ENV FLEXIO_FLOW_VERSION 0.6.0

RUN mkdir -p /flexio-flow
RUN git clone --branch $FLEXIO_FLOW_VERSION https://github.com/flexiooss/flexio-flow.git /flexio-flow
RUN bash /flexio-flow/venv.sh
COPY flexio-flow /usr/local/bin/
RUN chmod a+x  /usr/local/bin/flexio-flow


VOLUME ["$USER_HOME_DIR/.m2", "/src"]
WORKDIR /src

RUN rm -f /root/.m2/settings.xml

