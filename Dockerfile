FROM openjdk:8
MAINTAINER Swapnali Pingale <yeole.swapnali@gmail.com>

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

ENV DEBIAN_FRONTEND noninteractive

ENV DOWNLOAD_URL https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-7.3.6.tar.gz

ENV JIRA_HOME /var/atlassian/application-data/jira
ENV JIRA_INSTALL_DIR /opt/atlassian/jira

RUN apt-get update
RUN apt-get install -y wget git default-jre

RUN sudo /bin/sh -c 'echo JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::") >> /etc/environment'
RUN sudo /bin/sh -c 'echo JIRA_HOME=${JIRA_HOME} >> /etc/environment'

RUN mkdir -p /opt/atlassian
RUN mkdir -p ${JIRA_HOME}

RUN wget -P /tmp ${DOWNLOAD_URL}
RUN tar zxf /tmp/atlassian-jira-7.3.6.tar.gz -C /tmp
RUN mv /tmp/atlassian-jira-software-7.3.6-x64.bin /tmp/jira
RUN mv /tmp/jira /opt/atlassian/

RUN wget -P /tmp http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz
RUN tar zxf /tmp/mysql-connector-java-5.1.38.tar.gz -C /tmp
RUN mv /tmp/mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar ${JIRA_INSTALL_DIR}/lib/

VOLUME ["/var/atlassian/application-data/jira", "/opt/atlassian/jira/logs"]
WORKDIR /opt/atlassian/jira

CMD ["/opt/atlassian/jira/bin/start-jira.sh", "run"]

EXPOSE 8080

CMD ["/sbin/my_init"]

ENV MYSQL_USER root 
ENV MYSQL_PASS root

RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

RUN apt-get install -y mysql-server

RUN rm -rf /var/lib/mysql/*

ADD build/my.cnf /etc/mysql/my.cnf
ADD build/dbconfig.xml /var/atlassian/application-data/jira

RUN mkdir /etc/mysql/run
ADD runit/mysql.sh /etc/mysql/run
RUN chmod +x /etc/mysql/run

ADD build/setup /root/setup

ADD my_init.d/99_mysql_setup.sh /etc/my_init.d/99_mysql_setup.sh
RUN chmod +x /etc/my_init.d/99_mysql_setup.sh

EXPOSE 3306

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
