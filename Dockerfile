# Start with Ubuntu base image
FROM ubuntu:14.04
MAINTAINER Sai Teja <Madabhushi.Saiteja@zapcg.com>

# Install LXDE, VNC server, XRDP and Firefox
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  lxde-core \
  lxterminal \
  tightvncserver \
  xrdp \
  wget \
  bzip2

#Install Firefox
RUN wget http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/46.0.1/linux-x86_64/en-US/firefox-46.0.1.tar.bz2 -P /opt/
RUN bunzip2 /opt/firefox-46.0.1.tar.bz2
RUN tar xvf /opt/firefox-46.0.1.tar -C /opt/ 
RUN sudo ln -s /opt/firefox/firefox /usr/bin/firefox
ENV DISPLAY=:1

# Set user for VNC server (USER is only for build)
ENV USER root
# Set default password
COPY password.txt .
RUN cat password.txt password.txt | vncpasswd && \
  rm password.txt
# Expose VNC port
EXPOSE 5901

# Set XDRP to use TightVNC port
RUN sed -i '0,/port=-1/{s/port=-1/port=5901/}' /etc/xrdp/xrdp.ini

# Copy VNC script that handles restarts
COPY vnc.sh /opt/

ENV TOMCAT_VERSION 8.0.52

# Set locales
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LC_CTYPE en_GB.UTF-8

# Fix sh
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install dependencies
RUN apt-get update && \
apt-get install -y git build-essential curl wget software-properties-common 

# Install supervisor
RUN apt-get update && \
apt-get install -y supervisor


# Install JDK 8
RUN \
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
add-apt-repository -y ppa:webupd8team/java && \
apt-get update && \
apt-get install -y oracle-java8-installer wget unzip tar && \
rm -rf /var/lib/apt/lists/* && \
rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Get Tomcat
RUN wget --quiet --no-cookies http://apache.rediris.es/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -O /tmp/tomcat.tgz && \
tar xzvf /tmp/tomcat.tgz -C /opt && \
mv /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat && \
rm /tmp/tomcat.tgz && \
rm -rf /opt/tomcat/webapps/examples && \
rm -rf /opt/tomcat/webapps/docs && \
rm -rf /opt/tomcat/webapps/ROOT


ENV CATALINA_HOME /opt/tomcat
ENV PATH $PATH:$CATALINA_HOME/bin

EXPOSE 8080
EXPOSE 8009
VOLUME "/opt/tomcat/webapps"
WORKDIR /
ENV USER root

#Tor Browser Setup
RUN mkdir -p /home/centos
RUN wget https://torify.me/assets/downloads/tor-browser-linux64-7.5.5_en-US.tar.xz -P /home/centos/
RUN tar xf /home/centos/tor-browser-linux64-7.5.5_en-US.tar.xz -C /home/centos/
RUN sed -i '94,97 s/^/#/' /home/centos/tor-browser_en-US/Browser/start-tor-browser

#Disable firefox Update
RUN sudo apt-mark hold firefox

RUN echo "[supervisord]" > /etc/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:vnc]" >> /etc/supervisord.conf && \
    echo "command=/opt/vnc.sh" >> /etc/supervisord.conf && \
    echo "[program:Dsiplay]" >> /etc/supervisord.conf && \
    echo "command=export DISPLAY=:1" >> /etc/supervisord.conf && \
    echo "[program:tomcat]" >> /etc/supervisord.conf && \
    echo "command=/opt/tomcat/bin/catalina.sh run" >> /etc/supervisord.conf     

CMD ["/usr/bin/supervisord"]

    
