#!/bin/bash
set -x

# If not set, set node id manually to be passed in via setenv.sh
if [ "${NODE_ID}" = "NONE" ]; then
  NODE_ID=${NODE_ID_PREFIX}${HOSTNAME}
  export NODE_ID
fi

# create target diretory for heap dumps
mkdir -p ${HEAP_DUMP_PATH}

# Unset INDEX_DIRECTORY if set to NONE
if [ "NONE" = "${INDEX_DIRECTORY}" ]; then
    INDEX_DIRECTORY=
    export INDEX_DIRECTORY
fi

# Run tomcat if the first argument is run otherwise try to run whatever the argument is a command
if [ "$1" = 'run' ]; then
  exec catalina.sh "$@"
else
  exec "$@"
fi
