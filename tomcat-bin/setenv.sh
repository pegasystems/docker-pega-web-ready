#!/usr/bin/env bash

#
# Run headless
#
JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true"

#
# Append security overwrites
#
JAVA_OPTS="${JAVA_OPTS} -Djava.security.properties=${CATALINA_HOME}/conf/java.security.overwrite"

#
# Pass Node tier to Pega
#
JAVA_OPTS="${JAVA_OPTS} -DNodeTier=${NODE_TIER}"

#
# Setup Heapdump path
#
JAVA_OPTS="${JAVA_OPTS} -XX:HeapDumpPath=${HEAP_DUMP_PATH}"

# Pega log directory (set before existing JAVA_OPTS so that duplicate settings in JAVA_OPTS will win)
JAVA_OPTS="-Dpega.logdir=${CATALINA_HOME}/logs/${HOSTNAME} ${JAVA_OPTS}"

# Heap size settings (set before existing JAVA_OPTS so that duplicate settings in JAVA_OPTS will win)
JAVA_OPTS="-Xms${INITIAL_HEAP} -Xmx${MAX_HEAP} ${JAVA_OPTS}"

# Settings to run hazelcast in modular java (i.e. java 9 and newer)
JAVA_OPTS="${JAVA_OPTS} --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.ibm.lang.management.internal=ALL-UNNAMED \
--add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED"

krb5_conf="/opt/pega/kerberos/krb5.conf"
#
# Adding krb5.conf location to JAVA_OPTS
#
if [ -e "$krb5_conf" ]; then
  echo "Adding ${krb5_conf} to JAVA_OPTS";
  JAVA_OPTS="${JAVA_OPTS} -Djava.security.krb5.conf=${krb5_conf}"
else
  echo "No krb5.conf was specified in ${krb5_conf}."
fi

echo "JAVA_OPTS: \"${JAVA_OPTS}\""
export  JAVA_OPTS

# Node settings
CATALINA_OPTS="${CATALINA_OPTS} -Didentification.nodeid=${HOSTNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DNodeType=${NODE_TYPE}"
CATALINA_OPTS="${CATALINA_OPTS} -DNodeSettings=\"Pega-IntegrationEngine/EnableRequestorPools=false;${NODE_SETTINGS}\""

# Index settings
#  When left blank, disable indexing.
CATALINA_OPTS="${CATALINA_OPTS} -Dindex.directory=${INDEX_DIRECTORY}"

if [ -n "${MAX_RETRIES}" ] && [ -n "${RETRY_TIMEOUT}" ]; then
  # Classloader Timeout settings
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.pega.pegarules.bootstrap.maxretries=${MAX_RETRIES}"
  CATALINA_OPTS="${CATALINA_OPTS} -Dcom.pega.classloader.retrytimeout=${RETRY_TIMEOUT}"
fi

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
  CATALINA_OPTS="${CATALINA_OPTS} -Dprconfig/dsm/services/stream/pyUnpackBasePath=/tmp/kafka "
  CATALINA_OPTS="${CATALINA_OPTS} -Dprconfig/dsm/services/stream/server_properties/unclean.leader.election.enable=false "
fi

# recommended non-overridable  JVM Arguments
CATALINA_OPTS="${CATALINA_OPTS} -XX:+DisableExplicitGC"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.security.egd=file:///dev/urandom"
# recommended overridable JVM Arguments 
CATALINA_OPTS="-XX:+UseStringDeduplication ${CATALINA_OPTS}"
CATALINA_OPTS="-Xlog:gc*,gc+heap=debug,gc+humongous=debug:file=${CATALINA_HOME}/logs/gc.log:uptime,pid,level,time,tags:filecount=3,filesize=2M ${CATALINA_OPTS}"

echo "CATALINA_OPTS: \"${CATALINA_OPTS}\""

