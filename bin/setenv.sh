#!/usr/bin/env bash

#
# Run headless
#
JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true"

#
# Append security overwrites
#
JAVA_OPTS="${JAVA_OPTS} -Djava.security.properties=/usr/local/tomcat/conf/java.security.overwrite"
#
# Setup Heapdump path
#
JAVA_OPTS="${JAVA_OPTS} -XX:HeapDumpPath=${HEAP_DUMP_PATH}"

echo JAVA_OPTS: \"${JAVA_OPTS}\"
export  JAVA_OPTS

CATALINA_OPTS=""

# Tomcat Listener Settings
CATALINA_OPTS="${CATALINA_OPTS} -DmaxThreads=${MAX_THREADS}"

# Database connection settings
CATALINA_OPTS="${CATALINA_OPTS} -DdbName=${DB_NAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DdbHostname=${DB_HOST}"
CATALINA_OPTS="${CATALINA_OPTS} -DdbPort=${DB_PORT}"
CATALINA_OPTS="${CATALINA_OPTS} -DdbUsername=${DB_USERNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DdbPassword=${DB_PASSWORD}"

# JDBC connection settings
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcUrl=${JDBC_URL}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcMinActive=${JDBC_MIN_ACTIVE}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcMaxActive=${JDBC_MAX_ACTIVE}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcMinIdle=${JDBC_MIN_IDLE}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcMaxIdle=${JDBC_MAX_IDLE}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcMaxWait=${JDBC_MAX_WAIT}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcInitialSize=${JDBC_INITIAL_SIZE}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcDriverClass=${JDBC_CLASS}"
CATALINA_OPTS="${CATALINA_OPTS} -DjdbcValidationQuery='${JDBC_VALIDATION_QUERY}'"

# Pega DB Schema settings
CATALINA_OPTS="${CATALINA_OPTS} -DrulesSchema=${RULES_SCHEMA}"
CATALINA_OPTS="${CATALINA_OPTS} -DdataSchema=${DATA_SCHEMA}"

# Node settings introduced in 7.1.9
CATALINA_OPTS="${CATALINA_OPTS} -Didentification.nodeid=${NODE_ID}"

# Index settings introduced in 7.1.10
#  When left blank, disable indexing.
CATALINA_OPTS="${CATALINA_OPTS} -Dindex.directory=${INDEX_DIRECTORY}"

#
# Setup JMX
#
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=${JMX_PORT}"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.rmi.server.hostname=${JMX_SERVER_HOSTNAME}"	

#
# Setup SMA with auto discovery
#
CATALINA_OPTS="${CATALINA_OPTS} -DSMAAutoNodeDiscovery=true "
CATALINA_OPTS="${CATALINA_OPTS} -DSMAAutoNodeDiscoveryJMXPort=${JMX_PORT} "
CATALINA_OPTS="${CATALINA_OPTS} -DSMAAutoNodeDiscoveryPort=8080 "

echo CATALINA_OPTS: \"${CATALINA_OPTS}\"

