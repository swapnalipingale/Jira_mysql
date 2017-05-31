FROM openjdk:8
MAINTAINER Swapnali Pingale <yeole.swapnali@gmail.com>

ENV HOME /root

ENV DEBIAN_FRONTEND noninteractive

ENV DOWNLOAD_URL https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-7.3.6.tar.gz
ENV JIRA_HOME /var/atlassian/application-data/jira
ENV JIRA_INSTALL_DIR /opt/atlassian/jira

RUN apt-get update
RUN apt-get install -y wget git default-jre

RUN set -x \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends -t jessie-backports libtcnative-1 \
    && apt-get clean \
    && mkdir -p                "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_HOME}/caches/indexes" \
    && chmod -R 700            "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_INSTALL_DIR}/conf/Catalina" \
    && sed --in-place          "s/java version/openjdk version/g" "${JIRA_INSTALL_DIR}/bin/check-java.sh" \
    && echo -e                 "\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL_DIR}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"           "${JIRA_INSTALL}/conf/server.xml"

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
