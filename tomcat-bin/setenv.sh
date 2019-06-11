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

# Pega log directory
JAVA_OPTS="${JAVA_OPTS} -Dpega.logdir=${CATALINA_HOME}/logs/${HOSTNAME}"

# Heap size settings (set before existing JAVA_OPTS so that duplicate settings in JAVA_OPTS will win)
JAVA_OPTS="-Xms${INITIAL_HEAP} -Xmx${MAX_HEAP} ${JAVA_OPTS}"

echo JAVA_OPTS: \"${JAVA_OPTS}\"
export  JAVA_OPTS

CATALINA_OPTS=""

# Tomcat Listener Settings
CATALINA_OPTS="${CATALINA_OPTS} -DmaxThreads=${MAX_THREADS}"

# Node settings
CATALINA_OPTS="${CATALINA_OPTS} -Didentification.nodeid=${HOSTNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DNodeType=${NODE_TYPE}"
CATALINA_OPTS="${CATALINA_OPTS} -DNodeSettings=\"${NODE_SETTINGS}\""

# Index settings
#  When left blank, disable indexing.
CATALINA_OPTS="${CATALINA_OPTS} -Dindex.directory=${INDEX_DIRECTORY}"

# Setup JMX
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=${JMX_PORT}"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.rmi.server.hostname=${JMX_SERVER_HOSTNAME}"	

# Setup SMA with auto discovery
CATALINA_OPTS="${CATALINA_OPTS} -DSMAAutoNodeDiscovery=true "
CATALINA_OPTS="${CATALINA_OPTS} -DSMAAutoNodeDiscoveryJMXPort=${JMX_PORT} "
CATALINA_OPTS="${CATALINA_OPTS} -DSMAAutoNodeDiscoveryPort=8080 "

echo CATALINA_OPTS: \"${CATALINA_OPTS}\"

