# Docker-in-Docker Jenkins Slave
#
# See: https://github.com/tehranian/dind-jenkins-slave
# See: https://dantehranian.wordpress.com/2014/10/25/building-docker-images-within-docker-containers-via-jenkins/
#
# Following the best practices outlined in:
#   http://jonathan.bergknoff.com/journal/building-good-docker-images

FROM basip/jenkins-slave

ENV DEBIAN_FRONTEND noninteractive

# Adapted from: https://registry.hub.docker.com/u/jpetazzo/dind/dockerfile/
# Let's start with some basic stuff.
RUN apt-get update -qq && apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    gpg-agent \
    curl \
    zip \
    sudo \
    wget \
    software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN usermod -a -G sudo jenkins

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
# Install Docker from Docker Inc. repositories.
RUN apt-get update -qq && apt-get install -qqy docker-ce=5:19.03.5~3-0~ubuntu-bionic && rm -rf /var/lib/apt/lists/*

ADD wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker
VOLUME /var/lib/docker

#Install SonarQube Scanner

ENV SONAR_SCANNER_VERSION 4.2.0.1873

RUN mkdir -p /opt && \
    wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip && \
    unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip && \
    mv sonar-scanner-${SONAR_SCANNER_VERSION}-linux /opt/sonar-scanner && \
    rm -rf sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip && \
    rm -rf /opt/sonar-scanner/conf/sonar-scanner.properties

ENV SONAR_SCANNER_VERSION /opt/sonar-scanner

ENV PATH $SONAR_SCANNER_VERSION/bin:$PATH

# Install NodeJS 13 for SonarQube scan

RUN curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
RUN apt-get install -y nodejs

# Make sure that the "jenkins" user from evarga's image is part of the "docker"
# group. Needed to access the docker daemon's unix socket.
RUN usermod -a -G docker jenkins

# place the jenkins slave startup script into the container
ADD jenkins-slave-startup.sh /
CMD ["/jenkins-slave-startup.sh"]
