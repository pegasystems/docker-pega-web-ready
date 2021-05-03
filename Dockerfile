# Dockerfile for Pega 8 Platform

# Base image to extend from
FROM pegasystems/tomcat:9-jdk11 as release

ARG VERSION

LABEL vendor="Pegasystems Inc." \
      name="Pega Tomcat Node" \
      version=${VERSION:-CUSTOM_BUILD}


# Creating new user and group

RUN groupadd -g 9001 pegauser && \
    useradd -r -u 9001 -g pegauser -G root pegauser

RUN groupadd -g 1337 tomcat && \
    useradd -r -u 1337 -g tomcat --create-home tomcat

RUN apt-get update && \
    apt-get install -y sudo && \
    rm -rf /var/lib/apt/lists/*
           
RUN rm -rf /etc/sudoers && \
    echo "Defaults>ALL passwd_tries=0" > /etc/sudoers && \
    echo "pegauser ALL=(tomcat) NOPASSWD: SETENV: ALL" >> /etc/sudoers

ENV PEGA_DOCKER_VERSION=${VERSION:-CUSTOM_BUILD}

# Limit permissions for curl
RUN chmod 750 /usr/bin/curl

# Create directory for storing heapdump
RUN mkdir -p /heapdumps  && \
    chmod 770 /heapdumps && \
    chown -R pegauser /heapdumps

# Create common directory for mounting configuration and libraries
RUN mkdir -p /opt/pega && \
    chmod -R g+rw /opt/pega && \
    chown -R pegauser /opt/pega

# Create directory for filesystem repository
RUN  mkdir -p /opt/pega/filerepo  && \
     chmod -R g+rw /opt/pega/filerepo && \
     chown -R pegauser /opt/pega/filerepo

# Create directory for mounting configuration files
RUN  mkdir -p /opt/pega/config  && \
     chmod -R g+rw /opt/pega/config && \
     chown -R pegauser /opt/pega/config

# Create directory for mounting libraries
RUN  mkdir -p /opt/pega/lib  && \
     chmod -R g+rw /opt/pega/lib && \
     chown -R pegauser /opt/pega/lib

# Create directory for mounting secrets
RUN  mkdir -p /opt/pega/secrets && \
     chmod -R g+rw /opt/pega/secrets && \
     chown -R pegauser /opt/pega/secrets


# Create directory for extracted prweb.war
RUN mkdir -p /opt/pega/prweb && \
    chmod -R g+rw /opt/pega/prweb && \
    chown -R pegauser /opt/pega/prweb

# Create directory for extra stream volume
RUN mkdir -p /opt/pega/streamvol && \
    chmod -R g+rw /opt/pega/streamvol && \
    chown -R pegauser /opt/pega/streamvol

# If this is set to true, run pega as a user that has constrained access. 
ENV RUN_AS_RESTRICTED_USER=false

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
    JDBC_INITIAL_SIZE=4 \
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
ENV JMX_PORT=9001 \
    USE_CUSTOM_JMX_CONNECTION=

# Configure Cassandra.
ENV CASSANDRA_CLUSTER=false \
    CASSANDRA_NODES= \
    CASSANDRA_PORT=9042 \
    CASSANDRA_USERNAME= \
    CASSANDRA_PASSWORD= \
    CASSANDRA_CLIENT_ENCRYPTION=false \
    CASSANDRA_TRUSTSTORE= \
    CASSANDRA_TRUSTSTORE_PASSWORD= \
    CASSANDRA_KEYSTORE= \
    CASSANDRA_KEYSTORE_PASSWORD=

# Configure search nodes. Empty string falls back to search being done on the nodes themselves.
ENV PEGA_SEARCH_URL=

# Configure hazelcast. By default, hazelcast runs in embedded mode.
ENV HZ_CLIENT_MODE=false \
    HZ_DISCOVERY_K8S= \
    HZ_CLUSTER_NAME= \
    HZ_SERVER_HOSTNAME= \
    HZ_CS_AUTH_USERNAME= \
    HZ_CS_AUTH_PASSWORD=

#Set up volume for persistent Kafka data storage
RUN  mkdir -p /opt/pega/kafkadata && \
     chmod -R 777 /opt/pega/kafkadata && \
     chown -R pegauser /opt/pega/kafkadata

RUN mkdir /search_index && \
    chmod -R 777 /search_index && \
    chown -R pegauser /search_index
    
# Set up dir for prometheus lib
RUN mkdir -p /opt/pega/prometheus && \
    curl -sL -o /opt/pega/prometheus/jmx_prometheus_javaagent.jar https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.15.0/jmx_prometheus_javaagent-0.15.0.jar && \
    chmod -R 777 /opt/pega/prometheus && \
    chown -R pegauser /opt/pega/prometheus && \
    chmod 444 /opt/pega/prometheus/jmx_prometheus_javaagent.jar
    
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
RUN mkdir -p ${CATALINA_HOME}/work/Catalina/localhost/prweb && \
    chmod -R 775 ${CATALINA_HOME}  && \
    chmod -R 777 ${CATALINA_HOME}/logs && \
    chmod -R 777 ${CATALINA_HOME}/work/Catalina/localhost/prweb && \    
    chmod -R 777 ${CATALINA_HOME}/temp && \  
    chown -R pegauser ${CATALINA_HOME} 


#running in pegauser context
RUN chmod 770 /scripts/docker-entrypoint.sh

#switched the user to pegauser
USER pegauser

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["run"]

# Expose required ports

# HTTP is 8080, JMX is 9001, prometheus is 9090, Hazelcast is 5701-5710, Ignite is 47100, REST for Kafka is 7003
EXPOSE 8080 9001 9090 5701-5710 47100 7003

# *****Target for test environment*****

FROM release as qualitytest
USER root
RUN mkdir /tests && \
    chown -R pegauser /tests
COPY tests /tests
RUN chmod -R 777 /tests
USER pegauser
FROM release
