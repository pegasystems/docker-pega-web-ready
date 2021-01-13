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
# Pass Node tier to Pega
#
JAVA_OPTS="${JAVA_OPTS} -DNodeTier=${NODE_TIER}"

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

# Tomcat Listener Settings
CATALINA_OPTS="${CATALINA_OPTS} -DmaxThreads=${MAX_THREADS}"

# Node settings
CATALINA_OPTS="${CATALINA_OPTS} -Didentification.nodeid=${HOSTNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DNodeType=${NODE_TYPE}"
CATALINA_OPTS="${CATALINA_OPTS} -DNodeSettings=\"Pega-IntegrationEngine/EnableRequestorPools=false;${NODE_SETTINGS}\""

# Index settings
#  When left blank, disable indexing.
CATALINA_OPTS="${CATALINA_OPTS} -Dindex.directory=${INDEX_DIRECTORY}"

# If not setting USE_CUSTOM_JMX_CONNECTION to "true", specify default JVM arguments for JMX
if [ "${USE_CUSTOM_JMX_CONNECTION}" != "true" ]; then
  # Setup OOTB JMX connectivity
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote"
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=${JMX_PORT}"
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"	
fi

# Provide setting required for stream node 
if [ "${IS_STREAM_NODE}" = "true" ]; then
  CATALINA_OPTS="${CATALINA_OPTS} -Dprconfig/dsm/services=StreamServer "
  CATALINA_OPTS="${CATALINA_OPTS} -Dprconfig/dsm/services/stream/pyUnpackBasePath/tmp/kafka "
  CATALINA_OPTS="${CATALINA_OPTS} -Dprconfig/dsm/services/stream/server_properties/unclean.leader.election.enable=false "
fi

# recommended non-overridable  JVM Arguments
CATALINA_OPTS="${CATALINA_OPTS} -XX:+DisableExplicitGC"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.security.egd=file:///dev/urandom"
CATALINA_OPTS="${CATALINA_OPTS} -XX:+ExitOnOutOfMemoryError"
# recommended overridable JVM Arguments 
CATALINA_OPTS="-XX:+UseStringDeduplication ${CATALINA_OPTS}"

echo CATALINA_OPTS: \"${CATALINA_OPTS}\"

