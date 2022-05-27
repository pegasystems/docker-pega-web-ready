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

tls_cert_root="${pega_root}/tomcatcertsmount"
mkdir -p $tls_cert_root

tomcat_cert_root="${pega_root}/tomcatcerts"
mkdir -p $tomcat_cert_root


prlog4j2="${config_root}/prlog4j2.xml"
prconfig="${config_root}/prconfig.xml"
context_xml="${config_root}/context.xml"
server_xml="${config_root}/server.xml"
web_xml="${config_root}/web.xml"
tomcatusers_xml="${config_root}/tomcat-users.xml"

db_username_file="${secret_root}/DB_USERNAME"
db_password_file="${secret_root}/DB_PASSWORD"

cassandra_username_file="${secret_root}/CASSANDRA_USERNAME"
cassandra_password_file="${secret_root}/CASSANDRA_PASSWORD"
cassandra_truststore_password_file="${secret_root}/CASSANDRA_TRUSTSTORE_PASSWORD"
cassandra_keystore_password_file="${secret_root}/CASSANDRA_KEYSTORE_PASSWORD"

pega_diagnostic_username_file="${secret_root}/PEGA_DIAGNOSTIC_USER"
pega_diagnostic_password_file="${secret_root}/PEGA_DIAGNOSTIC_PASSWORD"

hazelcast_username_file="${secret_root}/HZ_CS_AUTH_USERNAME"
hazelcast_password_file="${secret_root}/HZ_CS_AUTH_PASSWORD"

custom_artifactory_username_file="${secret_root}/CUSTOM_ARTIFACTORY_USERNAME"
custom_artifactory_password_file="${secret_root}/CUSTOM_ARTIFACTORY_PASSWORD"
custom_artifactory_apikey_header_file="${secret_root}/CUSTOM_ARTIFACTORY_APIKEY_HEADER"
custom_artifactory_apikey_file="${secret_root}/CUSTOM_ARTIFACTORY_APIKEY"

#tomcat ssl certs
tomcat_keystore_password_file="${tls_cert_root}/TOMCAT_KEYSTORE_PASSWORD"
tomcat_keystore_file="${tls_cert_root}/TOMCAT_KEYSTORE_CONTENT"

if [ -e "$tomcat_keystore_password_file" ]; then
   export TOMCAT_KEYSTORE_PASSWORD=$(<${tomcat_keystore_password_file})
else
   export TOMCAT_KEYSTORE_PASSWORD=${TOMCAT_KEYSTORE_PASSWORD}
fi

if [ -e "$tomcat_keystore_file" ]; then
  echo "TLS certificate for tomcat exists"
  cat ${tomcat_keystore_file} | xargs printf '%b\n' | base64 --decode > "${tomcat_cert_root}/tlskeystore.jks"
  export TOMCAT_KEYSTORE_DIR="${tomcat_cert_root}/tlskeystore.jks"
else
  echo "TLS certificate does not exist"
fi

# Define the JDBC_URL variable based on inputs
if [ "$JDBC_URL" == "" ]; then
  echo "JDBC_URL must be specified.";
  exit 1
fi
if [ "$JDBC_CLASS" == "" ]; then
  echo "JDBC_CLASS must be specified.";
  exit 1
fi

if [ -e "$custom_artifactory_username_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_USERNAME=$(<${custom_artifactory_username_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_USERNAME=${CUSTOM_ARTIFACTORY_USERNAME}
fi

if [ -e "$custom_artifactory_password_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_PASSWORD=$(<${custom_artifactory_password_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_PASSWORD=${CUSTOM_ARTIFACTORY_PASSWORD}
fi

if [ -e "$custom_artifactory_apikey_header_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER=$(<${custom_artifactory_apikey_header_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER=${CUSTOM_ARTIFACTORY_APIKEY_HEADER}
fi

if [ -e "$custom_artifactory_apikey_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY=$(<${custom_artifactory_apikey_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY=${CUSTOM_ARTIFACTORY_APIKEY}
fi

custom_artifactory_auth=""
if [ "$SECRET_CUSTOM_ARTIFACTORY_USERNAME" != "" ] || [ "$SECRET_CUSTOM_ARTIFACTORY_PASSWORD" != "" ]; then
    if [ "$SECRET_CUSTOM_ARTIFACTORY_USERNAME" == "" ] || [ "$SECRET_CUSTOM_ARTIFACTORY_PASSWORD" == "" ]; then
        echo "SECRET_CUSTOM_ARTIFACTORY_USERNAME & SECRET_CUSTOM_ARTIFACTORY_PASSWORD must be specified for basic authentication for custom artifactory."
        exit 1
    else
        echo "Using basic authentication for custom artifactory to download JDBC driver."
        custom_artifactory_auth="-u "$SECRET_CUSTOM_ARTIFACTORY_USERNAME":"$SECRET_CUSTOM_ARTIFACTORY_PASSWORD
    fi
fi

if [[ "$custom_artifactory_auth" == "" && ( "$SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER" != "" || "$SECRET_CUSTOM_ARTIFACTORY_APIKEY" != "" ) ]]; then
    if [ "$SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER" == "" ] || [ "$SECRET_CUSTOM_ARTIFACTORY_APIKEY" == "" ]; then
        echo "SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER & SECRET_CUSTOM_ARTIFACTORY_APIKEY must be specified for authentication using api key for custom artifactory."
        exit 1
    else
        echo "Using API key for authentication of custom artifactory to download JDBC driver."
        custom_artifactory_auth="-H "$SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER":"$SECRET_CUSTOM_ARTIFACTORY_APIKEY
    fi
fi

custom_artifactory_certificate=''
if [ "$(ls -A "${pega_root}/artifactory/cert"/*)" ]; then
     if [ "$(ls "${pega_root}/artifactory/cert"/* | wc -l)" == 1 ]; then
       echo "Certificate is provided for custom artifactory's domain ssl verification."
       # get certificate name
       for certfile in "${pega_root}/artifactory/cert"/*
        do
           echo "folder name: ${pega_root}/artifactory/cert"
           filename=$(basename "$certfile")
           ext="${filename##*.}"
           echo "$filename"
           if [ "$ext" = "cer" ] || [ "$ext" = "pem" ] || [ "$ext" = "crt" ] || [ "$ext" = "der" ]; then
              echo "$certfile"
              custom_artifactory_certificate="--cacert "$certfile
           else
              echo "curl needs valid format certificate file for ssl verification."
              exit 1
           fi
        done
     else
       echo "Provide one certificate file. The file may contain multiple CA certificates."
       exit 1
     fi
fi

if [ "$JDBC_DRIVER_URI" != "" ]; then
  curl_cmd_options=''
  if [ "$ENABLE_CUSTOM_ARTIFACTORY_SSL_VERIFICATION" == true ]; then
    echo "Establishing a secure connection to download driver."
    curl_cmd_options="curl -sSL $custom_artifactory_auth $custom_artifactory_certificate"
  else
    echo "Establishing an insecure connection to download driver."
    curl_cmd_options="curl -ksSL $custom_artifactory_auth"
  fi

  urls=$(echo $JDBC_DRIVER_URI | tr "," "\n")
  for url in $urls
    do
     echo "Downloading database driver: ${url}";
     jarabsurl="$(cut -d'?' -f1 <<<"$url")"
     echo "$jarabsurl"
     filename=$(basename $jarabsurl)
     if $curl_cmd_options --output /dev/null --silent --fail -r 0-0 $url
     then
       $curl_cmd_options -o ${lib_root}/$filename ${url}
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

# import certificates to jvm keystore
for certfile in "${pega_root}/certs"/*
do
    echo "folder name: ${pega_root}/certs"
    filename=$(basename "$certfile")
    ext="${filename##*.}"
    echo "$filename"
    if [ "$ext" = "cer" ] || [ "$ext" = "pem" ] || [ "$ext" = "crt" ] || [ "$ext" = "der" ]; then
      echo "${filename%.*}"cert
      keytool -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt -trustcacerts -importcert -alias "${filename%.*}"cert -file $certfile
    fi
done

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
  export NODE_TYPE="BackgroundProcessing,Search,Batch,RealTime,Custom1,Custom2,Custom3,Custom4,Custom5,BIX"
elif [ "${NODE_TYPE}" = "Stream" ]; then
  export NODE_TYPE="Stream"
fi
shopt -u nocasematch

# Various checks surrounding the use of our NodeTypes
for i in ${NODE_TYPE//,/ }; do
  if [[ "$i" =~ ^(DDS|Universal)$ ]]; then
    echo "NODE_TYPE ($i) IS NOT SUPPORTED BY THIS IMAGE."
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

if [ -e "$cassandra_truststore_password_file" ]; then
   export SECRET_CASSANDRA_TRUSTSTORE_PASSWORD=$(<${cassandra_truststore_password_file})
else
   export SECRET_CASSANDRA_TRUSTSTORE_PASSWORD=${CASSANDRA_TRUSTSTORE_PASSWORD}
fi

if [ -e "$cassandra_keystore_password_file" ]; then
   export SECRET_CASSANDRA_KEYSTORE_PASSWORD=$(<${cassandra_keystore_password_file})
else
   export SECRET_CASSANDRA_KEYSTORE_PASSWORD=${CASSANDRA_KEYSTORE_PASSWORD}
fi

if [ -e "$hazelcast_username_file" ]; then
   export SECRET_HZ_CS_AUTH_USERNAME=$(<${hazelcast_username_file})
else
   export SECRET_HZ_CS_AUTH_USERNAME=${HZ_CS_AUTH_USERNAME}
fi

if [ -e "$hazelcast_password_file" ]; then
   export SECRET_HZ_CS_AUTH_PASSWORD=$(<${hazelcast_password_file})
else
   export SECRET_HZ_CS_AUTH_PASSWORD=${HZ_CS_AUTH_PASSWORD}
fi

if [ "HZ_CLIENT_MODE" == true ]; then
    if [ "$SECRET_HZ_CS_AUTH_USERNAME" == "" ] || [ "$SECRET_HZ_CS_AUTH_PASSWORD" == "" ]; then
        echo "HZ_CS_AUTH_USERNAME & HZ_CS_AUTH_PASSWORD must be specified in hazelcast client server mode deployments.";
        exit 1
    fi
fi

/bin/dockerize -template ${CATALINA_HOME}/webapps/ROOT/index.html:${CATALINA_HOME}/webapps/ROOT/index.html

appContextFileName=$(echo "${PEGA_APP_CONTEXT_PATH}"|sed 's/\//#/g')

if [ ${PEGA_APP_CONTEXT_PATH} != "prweb" ]; then
    # Move pega deployment out of webapps to avoid double deployment
    if [ ! -d "/opt/pega/prweb/WEB-INF" ]; then 
       cp -r ${PEGA_DEPLOYMENT_DIR}/* /opt/pega/prweb
       rm -rf ${PEGA_DEPLOYMENT_DIR}
       mv ${CATALINA_HOME}/conf/Catalina/localhost/prweb.xml ${CATALINA_HOME}/conf/Catalina/localhost/${appContextFileName}.xml
    fi   
    export PEGA_DEPLOYMENT_DIR=/opt/pega/prweb
fi

/bin/dockerize -template ${CATALINA_HOME}/conf/Catalina/localhost/${appContextFileName}.xml:${CATALINA_HOME}/conf/Catalina/localhost/${appContextFileName}.xml

#
# Copying mounted prlog4j2 file to webapps/prweb/WEB-INF/classes
#
if [ -e "$prlog4j2" ]; then
  echo "Loading prlog4j2 from ${prlog4j2}...";
  cp "$prlog4j2" ${PEGA_DEPLOYMENT_DIR}/WEB-INF/classes/
else
  echo "No prlog4j2 was specified in ${prlog4j2}.  Using defaults."
fi

#
# Copying mounted prconfig file to webapps/prweb/WEB-INF/classes
#
if [ -e "$prconfig" ]; then
  echo "Loading prconfig from ${prconfig}...";
  cp "$prconfig" ${PEGA_DEPLOYMENT_DIR}/WEB-INF/classes/
else
  echo "No prconfig was specified in ${prconfig}.  Using defaults."
fi

#
# Copying mounted server.xml file to conf
#
if [ -e "${server_xml}" ]; then
  echo "Loading server.xml from ${server_xml}...";
  cp "${server_xml}" "${CATALINA_HOME}/conf/"
elif [ -e "${config_root}/server.xml.tmpl" ]; then
  #server.xml.tmpl
  echo "No server.xml was specified in ${server_xml}.  Generating from templates."
  cp ${config_root}/server.xml.tmpl ${CATALINA_HOME}/conf/server.xml.tmpl
  /bin/dockerize -template ${CATALINA_HOME}/conf/server.xml.tmpl:${CATALINA_HOME}/conf/server.xml
else
  echo "No server.xml was specified in ${server_xml}. Using defaults."
fi

#
# Copying mounted web.xml file to conf
#
if [ -e "${web_xml}" ]; then
  echo "Loading web.xml from ${web_xml}...";
  cp "${web_xml}" "${PEGA_DEPLOYMENT_DIR}/WEB-INF/"
else
  echo "No web.xml was specified in ${web_xml}. Using defaults."
fi

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

    if [ "$SECRET_DB_USERNAME" == "" ] ; then
      echo "DB_USERNAME must be specified.";
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
rm ${CATALINA_HOME}/conf/server.xml.tmpl


unset DB_USERNAME DB_PASSWORD SECRET_DB_USERNAME SECRET_DB_PASSWORD CASSANDRA_USERNAME CASSANDRA_PASSWORD SECRET_CASSANDRA_USERNAME SECRET_CASSANDRA_PASSWORD PEGA_DIAGNOSTIC_USER PEGA_DIAGNOSTIC_PASSWORD SECRET_PEGA_DIAGNOSTIC_USER SECRET_PEGA_DIAGNOSTIC_PASSWORD PEGA_APP_CONTEXT_ROOT HZ_CS_AUTH_USERNAME SECRET_HZ_CS_AUTH_USERNAME HZ_CS_AUTH_PASSWORD SECRET_HZ_CS_AUTH_PASSWORD CASSANDRA_TRUSTSTORE_PASSWORD SECRET_CASSANDRA_TRUSTSTORE_PASSWORD CASSANDRA_KEYSTORE_PASSWORD SECRET_CASSANDRA_KEYSTORE_PASSWORD SECRET_CUSTOM_ARTIFACTORY_USERNAME SECRET_CUSTOM_ARTIFACTORY_PASSWORD CUSTOM_ARTIFACTORY_USERNAME CUSTOM_ARTIFACTORY_PASSWORD SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER SECRET_CUSTOM_ARTIFACTORY_APIKEY CUSTOM_ARTIFACTORY_APIKEY_HEADER CUSTOM_ARTIFACTORY_APIKEY ENABLE_CUSTOM_ARTIFACTORY_SSL_VERIFICATION TOMCAT_KEYSTORE_PASSWORD


unset pega_root lib_root config_root

# Run tomcat if the first argument is run otherwise try to run whatever the argument is a command
if [ "$1" = 'run' ]; then
  exec catalina.sh "$@"
else
  exec "$@"
fi
