# Dockerfile for Pega 8 Platform

# Base image to extend from
FROM pegasystems/tomcat:9-jdk11 as release

ARG VERSION

LABEL vendor="Pegasystems Inc." \
      name="Pega Tomcat Node" \
      version=${VERSION:-CUSTOM_BUILD}

# Creating new user and group

RUN groupadd -g 9001 pegauser && \
    useradd -r -u 9001 -g pegauser pegauser


ENV PEGA_DOCKER_VERSION=${VERSION:-CUSTOM_BUILD}

# Create directory for storing heapdump
RUN mkdir -p /heapdumps  && \
    chgrp -R 0 /heapdumps && \
    chmod 770 /heapdumps && \
    chown -R pegauser /heapdumps

# Create common directory for mounting configuration and libraries
RUN mkdir -p /opt/pega && \
    chgrp -R 0 /opt/pega && \
    chmod -R g+rw /opt/pega && \
    chown -R pegauser /opt/pega

# Create directory for filesystem repository
RUN  mkdir -p /opt/pega/filerepo  && \
     chgrp -R 0 /opt/pega/filerepo && \
     chmod -R g+rw /opt/pega/filerepo && \
     chown -R pegauser /opt/pega/filerepo

# Create directory for mounting configuration files
RUN  mkdir -p /opt/pega/config  && \
     chgrp -R 0 /opt/pega/config && \
     chmod -R g+rw /opt/pega/config && \
     chown -R pegauser /opt/pega/config

# Create directory for mounting libraries
RUN  mkdir -p /opt/pega/lib  && \
     chgrp -R 0 /opt/pega/lib && \
     chmod -R g+rw /opt/pega/lib && \
     chown -R pegauser /opt/pega/lib

# Create directory for mounting secrets
RUN  mkdir -p /opt/pega/secrets && \
     chgrp -R 0 /opt/pega && \
     chmod -R g+rw /opt/pega/secrets && \
     chown -R pegauser /opt/pega/secrets


# Create directory for extracted prweb.war
RUN mkdir -p /opt/pega/prweb && \
    chgrp -R 0 /opt/pega/prweb && \
    chmod -R g+rw /opt/pega/prweb

# Create directory for extra stream volume
RUN mkdir -p /opt/pega/streamvol && \
    chgrp -R 0 /opt/pega/streamvol && \
    chmod -R g+rw /opt/pega/streamvol && \
    chown -R pegauser /opt/pega/streamvol


# Set up an empty JDBC URL which will, if set to a non-empty value, be used in preference
# to the "constructed" JDBC URL
ENV JDBC_URL='' \
    DB_USERNAME='' \
    DB_PASSWORD='' \
    JDBC_CLASS=''

# Load a default PostgreSQL driver on startup
ENV JDBC_DRIVER_URI=''

# Provide variables for the JDBC connection string
ENV JDBC_MAX_ACTIVE=75 \
    JDBC_MIN_IDLE=3 \
    JDBC_MAX_IDLE=25 \
    JDBC_MAX_WAIT=30000 \
    JDBC_INITIAL_SIZE=10 \
    JDBC_CONNECTION_PROPERTIES=''

# Provide variables for the name of the rules, data, and customerdata schemas
ENV RULES_SCHEMA=rules \
    DATA_SCHEMA=data \
    CUSTOMERDATA_SCHEMA=

#Tomcat user environment variables for pega diagnostic user
ENV PEGA_DIAGNOSTIC_USER='' \
    PEGA_DIAGNOSTIC_PASSWORD=''

# Parameterize variables to customize the tomcat runtime
ENV MAX_THREADS="300" \
    JAVA_OPTS="" \
    MAX_HEAP="4096m" \
    INITIAL_HEAP="2048m" \
    INDEX_DIRECTORY="NONE" \
    HEAP_DUMP_PATH="/heapdumps" \
    NODE_TYPE="" \
    NODE_TIER="" \
    NODE_SETTINGS="" \
    PEGA_APP_CONTEXT_PATH=prweb \
    PEGA_DEPLOYMENT_DIR=${CATALINA_HOME}/webapps/prweb

# Configure Remote JMX support and bind to port 9001
ENV JMX_PORT=9001

# Configure Cassandra.
ENV CASSANDRA_CLUSTER=false \
    CASSANDRA_NODES= \
    CASSANDRA_PORT=9042 \
    CASSANDRA_USERNAME= \
    CASSANDRA_PASSWORD=

# Configure search nodes. Empty string falls back to search being done on the nodes themselves.
ENV PEGA_SEARCH_URL=

#Set up volume for persistent Kafka data storage
RUN  mkdir -p /opt/pega/kafkadata && \
     chgrp -R 0 /opt/pega/kafkadata && \
     chmod -R g+rw /opt/pega/kafkadata && \
     chown -R pegauser /opt/pega/kafkadata

# Remove existing webapps
RUN rm -rf ${CATALINA_HOME}/webapps/*

# Copy in tomcat configuration and application files
COPY tomcat-webapps ${CATALINA_HOME}/webapps/
COPY tomcat-bin ${CATALINA_HOME}/bin/
COPY tomcat-conf ${CATALINA_HOME}/conf/
COPY scripts /scripts

#Installing dockerize for generating config files using templates
RUN curl -sL https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar zxf - -C /bin/

# Update access of required directories to allow not running in root for openshift
RUN chmod -R g+rw ${CATALINA_HOME}/logs  && \
    chmod -R g+rw ${CATALINA_HOME}/lib  && \
    chmod -R g+rw ${CATALINA_HOME}/work  && \
    chmod -R g+rw ${CATALINA_HOME}/conf  && \
    chmod -R g+rw ${CATALINA_HOME}/bin  && \
    chmod -R g+rw ${CATALINA_HOME}/webapps && \
    chmod -R g+x /scripts && \
    chown -R pegauser /scripts && \
    chmod g+r ${CATALINA_HOME}/conf/web.xml && \
    chown -R pegauser ${CATALINA_HOME}  && \
    mkdir /search_index && \
    chmod -R g+w /search_index && \
    chown -R pegauser /search_index

#switched the user to pegauser
USER pegauser

#running in pegauser context
RUN chmod 770 /scripts/docker-entrypoint.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["run"]

# Expose required ports

# HTTP is 8080, JMX is 9001, Hazelcast is 5701-5710, Ignite is 47100, REST for Kafka is 7003
EXPOSE 8080 9001 5701-5710 47100 7003

# *****Target for test environment*****

FROM release as qualitytest
USER root
RUN mkdir /tests && \
    chown -R pegauser /tests
COPY tests /tests
RUN chmod -R 777 /tests
USER pegauser
FROM release
