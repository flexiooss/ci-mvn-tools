FROM openjdk:21-slim
ARG CI_TOOLS_IMAGE_VERSION

ENV APT_FLAGS="--no-install-recommends -y"
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install ${APT_FLAGS} curl tar bash wget

ENV MVN_VERSION=3.9.6
RUN wget https://dlcdn.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz -O /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz
RUN tar zxvf /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz -C /usr/local/

ENV MVN_LOCATION=/usr/local/apache-maven-${MVN_VERSION}

ENV PATH $MVN_LOCATION/bin:$PATH
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
# ENV MAVEN_MS "256m"
# ENV MAVEN_MX "512m"
# ENV MAVEN_OPTS "-Xms$MAVEN_MS -Xmx$MAVEN_MX"

RUN echo $PATH

####################
# nodejs
####################
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install ${APT_FLAGS} nodejs


RUN apt-get install ${APT_FLAGS} fontconfig fonts-dejavu git imagemagick ghostscript graphviz
RUN apt-get install ${APT_FLAGS} python-is-python3 2to3 python-dev-is-python3 python3 python3-pip python3-venv python3-requests
RUN apt-get install ${APT_FLAGS} gcc gnupg
RUN apt-get install ${APT_FLAGS} git
RUN apt-get install ${APT_FLAGS} openssh-client
RUN apt-get install ${APT_FLAGS} file
RUN apt-get install ${APT_FLAGS} libreoffice libreoffice-java-common 
RUN mkdir -p /home/.cache/dconf 
RUN chmod a+rwx  /home/.cache/dconf

RUN echo "***** INSTALL PHP *****"

RUN apt -y install software-properties-common python3-launchpadlib
RUN echo "deb https://ppa.launchpadcontent.net/ondrej/php/ubuntu/ jammy main" > /etc/apt/sources.list.d/ondrej-ubuntu-php-kinetic.list
RUN add-apt-repository ppa:ondrej/php -y
RUN apt -y install php7.4
RUN apt-get install ${APT_FLAGS} php7.4 php7.4-json php7.4-phar php7.4-iconv
RUN apt-get install ${APT_FLAGS} php7.4-dom php7.4-mbstring php7.4-xml php7.4-xmlwriter php7.4-tokenizer

RUN npm i -g raml2html
RUN npm install -g npm-cli-login

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

#RUN pip install --upgrade pip
#RUN pip install requests

COPY settings.xml /root/.m2/settings.xml

COPY download-poom-ci-utilities-pom.xml /tmp/download-poom-ci-utilities-pom.xml
RUN mvn clean install -f /tmp/download-poom-ci-utilities-pom.xml
RUN rm -f /tmp/download-poom-ci-utilities-pom.xml


COPY *.sh /usr/local/bin/
RUN chmod a+rx  /usr/local/bin/*.sh
RUN ls -al /usr/local/bin/
RUN cat /usr/local/bin/notify-stack-deployment.sh

RUN mkdir -p /m2
RUN mkdir -p /src

ENV USER_HOME_DIR="/root"

####################
# hotballoon-shed
####################
ENV HOTBALLOON_SHED_VERSION 1.90.0

RUN mkdir -p /hotballoon-shed
RUN git clone --branch $HOTBALLOON_SHED_VERSION https://github.com/flexiooss/hotballoon-shed.git /hotballoon-shed
RUN bash /hotballoon-shed/venv.sh
RUN bash /hotballoon-shed/hotballoon-shed.sh set-flexio-registry -S /hotballoon-shed
RUN bash /hotballoon-shed/hotballoon-shed.sh self-install
COPY hbshed /usr/local/bin/
RUN chmod a+x  /usr/local/bin/hbshed

####################
# flexio-flow
####################
ENV FLEXIO_FLOW_VERSION 0.26.0

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

RUN mkdir -p /.cache/composer/vcs
RUN chmod a+rwx  /.cache/composer/vcs
