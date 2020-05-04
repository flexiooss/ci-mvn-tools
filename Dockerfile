FROM openjdk:13-slim

ENV APT_FLAGS="--no-install-recommends -y"
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install ${APT_FLAGS} curl tar bash wget

ENV MVN_VERSION=3.6.3
RUN wget http://mirrors.standaloneinstaller.com/apache/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz -O /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz
RUN tar zxvf /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz -C /usr/local/

ENV MVN_LOCATION=/usr/local/apache-maven-${MVN_VERSION}

ENV PATH $MVN_LOCATION/bin:$PATH
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV MAVEN_MS "256m"
ENV MAVEN_MX "512m"
ENV MAVEN_OPTS "-Xms$MAVEN_MS -Xmx$MAVEN_MX"

RUN echo $PATH

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install ${APT_FLAGS} nodejs

RUN apt-get install ${APT_FLAGS} fontconfig ttf-dejavu git imagemagick ghostscript graphviz \
    php php-json php-phar php-iconv \
#    php-openssl
    php-dom php-mbstring php-xml php-xmlwriter php-tokenizer \
    python python-dev python3 python-pip python3-venv \
#    musl-dev \
    gcc gnupg git openssh-client file

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

####################
# hotballoon-shed
####################
ENV HOTBALLOON_SHED_VERSION 1.24.0

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
ENV FLEXIO_FLOW_VERSION 0.15.1

RUN mkdir -p /flexio-flow
RUN git clone --branch $FLEXIO_FLOW_VERSION https://github.com/flexiooss/flexio-flow.git /flexio-flow
RUN bash /flexio-flow/venv.sh
COPY flexio-flow /usr/local/bin/
RUN chmod a+x  /usr/local/bin/flexio-flow


VOLUME ["$USER_HOME_DIR/.m2", "/src"]
WORKDIR /src


####################
# cleanup
####################
RUN rm -rf /var/lib/apt/lists/*
RUN rm -f /root/.m2/settings.xml
RUN rm -rf /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz

####################
# tool versions
####################
RUN echo "CI Tools    : $CI_TOOLS_IMAGE_VERSION" >> /versions.txt
RUN echo "" >> /versions.txt
RUN mvn -version >> /versions.txt
RUN echo "Flexio Flow : $FLEXIO_FLOW_VERSION" >> /versions.txt
RUN echo "HB Shed     : $HOTBALLOON_SHED_VERSION" >> /versions.txt
RUN echo "NodeJS      : $(node --version)" >> /versions.txt
RUN echo "NPM         : $(npm --version)" >> /versions.txt
RUN echo "Python      : $(python --version)" >> /versions.txt
RUN echo "Python 3    : $(python3 --version)" >> /versions.txt
RUN cat /versions.txt
