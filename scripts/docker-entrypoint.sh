#!/bin/bash

echo "  ____                    ____             _             ";
echo " |  _ \ ___  __ _  __ _  |  _ \  ___   ___| | _____ _ __ ";
echo " | |_) / _ \/ _\` |/ _\` | | | | |/ _ \ / __| |/ / _ \ '__|";
echo " |  __/  __/ (_| | (_| | | |_| | (_) | (__|   <  __/ |   ";
echo " |_|   \___|\__, |\__,_| |____/ \___/ \___|_|\_\___|_|   ";
echo "            |___/                              v${PEGA_DOCKER_VERSION}";
echo " ";

#set -x

# the node_type needs to be defined for various checks below otherwise we
# risk an unknown state and potential failure. this value is the current
# default in PRPC if set to an empty-string
export NODE_TYPE=${NODE_TYPE:="WebUser,BackgroundProcessing,Search,Stream"}

# create directory properties and create the directories they point
# to if they don't already exist.
pega_root="/opt/pega"
mkdir -p $pega_root

lib_root="${pega_root}/lib"
mkdir -p $lib_root

config_root="${pega_root}/config"
mkdir -p $config_root

secret_root="${pega_root}/secrets"
mkdir -p $secret_root

context_xml="${config_root}/context.xml"
tomcatusers_xml="${config_root}/tomcat-users.xml"
prweb_war="${CATALINA_HOME}/webapps/prweb.war"

db_username_file="${secret_root}/DB_USERNAME"
db_password_file="${secret_root}/DB_PASSWORD"

cassandra_username_file="${secret_root}/CASSANDRA_USERNAME"
cassandra_password_file="${secret_root}/CASSANDRA_PASSWORD"

pega_diagnostic_username_file="${secret_root}/PEGA_DIAGNOSTIC_USER"
pega_diagnostic_password_file="${secret_root}/PEGA_DIAGNOSTIC_PASSWORD"

# Define the JDBC_URL variable based on inputs
if [ "$JDBC_URL" == "" ]; then
  echo "JDBC_URL must be specified.";
  exit 1
fi
if [ "$JDBC_CLASS" == "" ]; then
  echo "JDBC_CLASS must be specified.";
  exit 1
fi

if [ "$JDBC_DRIVER_URI" != "" ]; then
  urls=$(echo $JDBC_DRIVER_URI | tr "," "\n")
  for url in $urls
    do
     echo "Downloading database driver: ${url}";
     filename=$(basename $url)
     if curl --output /dev/null --silent --head --fail $url
     then
       curl -ksSL -o ${lib_root}/$filename ${url}
     else
       echo "Could not download jar from ${url}"
       exit 1
     fi
    done
fi

# copy jars mounted in the /opt/pega/lib directory of container to ${CATALINA_HOME}/lib
for srcfile in ${lib_root}/*
do
    filename=$(basename "$srcfile")
    ext="${filename##*.}"
    if [ "$ext" = "jar" ]; then
      \cp $srcfile "${CATALINA_HOME}/lib/"
    fi
done

echo "Using JDBC_URL: ${JDBC_URL}"

# Unset INDEX_DIRECTORY if set to NONE
if [ "NONE" = "${INDEX_DIRECTORY}" ]; then
    export INDEX_DIRECTORY=
fi

# Translate to internal names if NodeType is set to Foreground or Background
shopt -s nocasematch
# Translate to internal names if NodeType is set to Foreground or Background
if [ "${NODE_TYPE}" = "Foreground" ]; then
  export NODE_TYPE="WebUser"
elif [ "${NODE_TYPE}" = "Background" ]; then
  export NODE_TYPE="BackgroundProcessing,Search,ADM,Batch,RealTime,RTDG,Custom1,Custom2,Custom3,Custom4,Custom5,BIX"
elif [ "${NODE_TYPE}" = "Stream" ]; then
  export NODE_TYPE="Stream"
fi
shopt -u nocasematch

# Various checks surrounding the use of our NodeTypes
for i in ${NODE_TYPE//,/ }; do
  if [[ "$i" =~ ^(DDS|Universal)$ ]]; then
    echo "NODE_TYPE ($1) IS NOT SUPPORTED BY THIS IMAGE."
    exit 1
  elif [[ "$i" =~ ^Stream$ ]]; then

    # cookie of sorts used below, when running dockerize on our prweb.xml, to denote
    # if this instance is to be considered a Stream node and if so then apply the
    # necessary prweb configs.
    export IS_STREAM_NODE="true"
  elif [[ "$i" =~ ^Search$ ]]; then
    export INDEX_DIRECTORY="/search_index"
  fi
done

if [ -e "$cassandra_username_file" ]; then
   export SECRET_CASSANDRA_USERNAME=$(<${cassandra_username_file})
else
   export SECRET_CASSANDRA_USERNAME=${CASSANDRA_USERNAME}
fi

if [ -e "$cassandra_password_file" ]; then
   export SECRET_CASSANDRA_PASSWORD=$(<${cassandra_password_file})
else
   export SECRET_CASSANDRA_PASSWORD=${CASSANDRA_PASSWORD}
fi

/bin/dockerize -template ${CATALINA_HOME}/conf/Catalina/localhost/prweb.xml:${CATALINA_HOME}/conf/Catalina/localhost/prweb.xml

#
# Write config files from templates using dockerize ...
#
if [ -e "$context_xml" ]; then
  echo "Loading context.xml from ${context_xml}...";
  cp "$context_xml" ${CATALINA_HOME}/conf/
else
    if [ -e "$db_username_file" ]; then
       export SECRET_DB_USERNAME=$(<${db_username_file})
    else
       export SECRET_DB_USERNAME=${DB_USERNAME}
    fi

    if [ -e "$db_password_file" ]; then
       export SECRET_DB_PASSWORD=$(<${db_password_file})
    else
       export SECRET_DB_PASSWORD=${DB_PASSWORD}
    fi

    if [ "$SECRET_DB_USERNAME" == "" ] || [ "$SECRET_DB_PASSWORD" == "" ] ; then
      echo "DB_USERNAME and DB_PASSWORD must be specified.";
      exit 1
    fi

  echo "No context.xml was specified in ${context_xml}.  Generating from templates."
    if [ -e ${config_root}/context.xml.tmpl ] ; then
      cp ${config_root}/context.xml.tmpl ${CATALINA_HOME}/conf/context.xml.tmpl
    fi
  /bin/dockerize -template ${CATALINA_HOME}/conf/context.xml.tmpl:${CATALINA_HOME}/conf/context.xml
fi

if [ -e "$tomcatusers_xml" ]; then
  echo "Loading tomcat-users.xml from ${tomcatusers_xml}...";
  cp "$tomcatusers_xml" ${CATALINA_HOME}/conf/
else
    if [ -e "$pega_diagnostic_username_file" ]; then
       export SECRET_PEGA_DIAGNOSTIC_USER=$(<${pega_diagnostic_username_file})
    else
       export SECRET_PEGA_DIAGNOSTIC_USER=${PEGA_DIAGNOSTIC_USER}
    fi

    if [ -e "$pega_diagnostic_password_file" ]; then
       export SECRET_PEGA_DIAGNOSTIC_PASSWORD=$(<${pega_diagnostic_password_file})
    else
       export SECRET_PEGA_DIAGNOSTIC_PASSWORD=${PEGA_DIAGNOSTIC_PASSWORD}
    fi
    /bin/dockerize -template ${CATALINA_HOME}/conf/tomcat-users.xml.tmpl:${CATALINA_HOME}/conf/tomcat-users.xml
fi

rm ${CATALINA_HOME}/conf/context.xml.tmpl
rm ${CATALINA_HOME}/conf/tomcat-users.xml.tmpl


unset DB_USERNAME DB_PASSWORD SECRET_DB_USERNAME SECRET_DB_PASSWORD CASSANDRA_USERNAME CASSANDRA_PASSWORD SECRET_CASSANDRA_USERNAME SECRET_CASSANDRA_PASSWORD PEGA_DIAGNOSTIC_USER PEGA_DIAGNOSTIC_PASSWORD SECRET_PEGA_DIAGNOSTIC_USER SECRET_PEGA_DIAGNOSTIC_PASSWORD

unset pega_root lib_root config_root

# Run tomcat if the first argument is run otherwise try to run whatever the argument is a command
if [ "$1" = 'run' ]; then
  exec catalina.sh "$@"
else
  exec "$@"
fi
