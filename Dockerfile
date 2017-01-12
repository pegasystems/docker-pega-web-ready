# Base image on tomcat 7 with OpenJDK JRE 7
FROM tomcat:7-jre7

# Create pega directory for storing applications
RUN mkdir -p /opt/pega

# Setup global database variables
ENV DB_USERNAME pega
ENV DB_PASSWORD pegasys
ENV DB_HOST postgresql
ENV DB_PORT 5432
ENV DB_NAME pega

# Provide variables for the JDBC connection string
ENV JDBC_CLASS org.postgresql.Driver
ENV JDBC_DB_TYPE postgresql
ENV JDBC_URL_SUFFIX ''
ENV JDBC_MIN_ACTIVE 50
ENV JDBC_MAX_ACTIVE 250
ENV JDBC_MIN_IDLE 10
ENV JDBC_MAX_IDLE 50
ENV JDBC_MAX_WAIT 30000
ENV JDBC_INITIAL_SIZE 50

# Provide variables for the name of the rules and data schema
ENV RULES_SCHEMA pegarules
ENV DATA_SCHEMA pegadata

# Parameterize variables to customize the tomcat runtime
ENV MAX_THREADS 300
ENV JAVA_OPTS -Xms2048m -Xmx4096m -XX:PermSize=64m -XX:MaxPermSize=384m
ENV INDEX_DIRECTORY NONE
ENV HEAP_DUMP_PATH /heapdumps
ENV NODE_ID NONE

# Configure Remote JMX support and bind to port 9001
ENV JMX_PORT 9001
ENV JMX_SERVER_HOSTNAME 127.0.0.1
ENV TOMCAT_JMX_JAR_TGZ_URL https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/extras/catalina-jmx-remote.jar
RUN curl -kSL ${TOMCAT_JMX_JAR_TGZ_URL} -o catalina-jmx-remote.jar && curl -kSL ${TOMCAT_JMX_JAR_TGZ_URL}.asc -o catalina-jmx-remote.jar.asc && gpg --verify catalina-jmx-remote.jar.asc && mv catalina-jmx-remote.jar /usr/local/tomcat/lib/catalina-jmx-remote.jar && rm catalina-jmx-remote.jar.asc

# Copy in tomcat configuration and application files
COPY conf /usr/local/tomcat/conf/
COPY bin /usr/local/tomcat/bin/

# Copy in and configure customized entry point script
COPY docker-entrypoint.sh  /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]

# Expose the HTTP, SMA and JMX ports
EXPOSE 8080
EXPOSE 8090
EXPOSE 9001

# Expose the list of Hazelcast ports
EXPOSE 5701
EXPOSE 5702
EXPOSE 5703
EXPOSE 5704
EXPOSE 5705
EXPOSE 5706
EXPOSE 5707
EXPOSE 5708
EXPOSE 5709
EXPOSE 5710

# Expose Ignite port
EXPOSE 47100
