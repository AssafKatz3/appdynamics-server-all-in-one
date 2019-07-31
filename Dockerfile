FROM phusion/baseimage:0.11

MAINTAINER csek06

VOLUME ["/config"]

RUN export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive && \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 && \
apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' && \
apt-get update && \
apt-get install -y \
libaio1 numactl tzdata unzip iproute2 tomcat9 zulu-12 && \
usermod -u 99 nobody && \
usermod -g 100 nobody && \
mkdir -p /etc/my_init.d && \
mkdir -p /your-platform-install/defaults && \
mkdir -p /your-platform-install/install-scripts && \
mkdir -p /your-platform-install/startup-scripts && \
RUN export JAVA_HOME=/usr/lib/jvm/zulu-12-amd64 && \
RUN export CATALINA_HOME=/usr/share/tomcat9 && \
RUN export CATALINA_PID=/var/lib/tomcat9/tomcat.pid && \
RUN export CATALINA_BASE=/var/lib/tomcat9

COPY firstrun.sh /etc/my_init.d/firstrun.sh
COPY install-scripts/ /your-platform-install/defaults/install-scripts/
COPY startup-scripts/ /your-platform-install/defaults/startup-scripts/

RUN chmod +x /etc/my_init.d/firstrun.sh