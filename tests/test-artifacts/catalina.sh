#!/bin/bash
pega_diagnostic_username_file="/opt/pega/secrets/PEGA_DIAGNOSTIC_USER"
pega_diagnostic_password_file="/opt/pega/secrets/PEGA_DIAGNOSTIC_PASSWORD"

db_username_file="/opt/pega/secrets/DB_USERNAME"
db_password_file="/opt/pega/secrets/DB_PASSWORD"

cassandra_username_file="/opt/pega/secrets/CASSANDRA_USERNAME"
cassandra_password_file="/opt/pega/secrets/CASSANDRA_PASSWORD"

hazelcast_username_file="/opt/pega/secrets/HZ_CS_AUTH_USERNAME"
hazelcast_password_file="/opt/pega/secrets/HZ_CS_AUTH_PASSWORD"
hz_ssl_keystore_password_file="/opt/hazelcast/certs/HZ_SSL_KEYSTORE_PASSWORD"
hz_ssl_truststore_password_file="/opt/hazelcast/certs/HZ_SSL_TRUSTSTORE_PASSWORD"

custom_artifactory_username_file="/opt/pega/secrets/CUSTOM_ARTIFACTORY_USERNAME"
custom_artifactory_password_file="/opt/pega/secrets/CUSTOM_ARTIFACTORY_PASSWORD"
custom_artifactory_apikey_header_file="/opt/pega/secrets/CUSTOM_ARTIFACTORY_APIKEY_HEADER"
custom_artifactory_apikey_file="/opt/pega/secrets/CUSTOM_ARTIFACTORY_APIKEY"

stream_truststore_password_file="/opt/pega/secrets/STREAM_TRUSTSTORE_PASSWORD"
stream_keystore_password_file="/opt/pega/secrets/STREAM_KEYSTORE_PASSWORD"
stream_jaas_config_file="/opt/pega/secrets/STREAM_JAAS_CONFIG"

tomcat_keystore_password_file="/opt/pega/tomcatcertsmount/TOMCAT_KEYSTORE_PASSWORD"

if [ -e "$tomcat_keystore_password_file" ]; then
   export TOMCAT_KEYSTORE_PASSWORD=$(<${tomcat_keystore_password_file})
else
   export TOMCAT_KEYSTORE_PASSWORD=${TOMCAT_KEYSTORE_PASSWORD}
fi
echo "TLS certificate password is - $TOMCAT_KEYSTORE_PASSWORD"
echo "TLS certificate directory is - $TOMCAT_KEYSTORE_DIR"

echo "$NODE_TYPE"

echo "Index Directory Value - $INDEX_DIRECTORY"

echo "IsStreamNode - $IS_STREAM_NODE"

echo "Index Directory for Search - $INDEX_DIRECTORY"

if [ -e "$cassandra_username_file" ]; then
   export SECRET_CASSANDRA_USERNAME=$(<${cassandra_username_file})
else
   export SECRET_CASSANDRA_USERNAME=cassandra_username
fi

if [ -e "$cassandra_password_file" ]; then
   basename=CASSANDRA_PASSWORD
   export "SECRET_${basename}"="$(<${cassandra_password_file})"
else
   export SECRET_CASSANDRA_PASSWORD=cassandra_password
fi

echo "Cassandra Username is - $SECRET_CASSANDRA_USERNAME"

echo "Cassandra Password is - $SECRET_CASSANDRA_PASSWORD"

if [ -e "$hazelcast_username_file" ]; then
    export SECRET_HAZELCAST_USERNAME=$(<${hazelcast_username_file})
else
    export SECRET_HAZELCAST_USERNAME=hz_cs_auth_username
fi

if [ -e "$hazelcast_password_file" ]; then
    export SECRET_HAZELCAST_PASSWORD=$(<${hazelcast_password_file})
else
    export SECRET_HAZELCAST_PASSWORD=hz_cs_auth_password
fi

echo "Hazelcast Username is - $SECRET_HAZELCAST_USERNAME"

echo "Hazelcast Password is - $SECRET_HAZELCAST_PASSWORD"

if [ -e "$hz_ssl_keystore_password_file" ]; then
   export SECRET_HZ_SSL_KEYSTORE_PASSWORD=$(<${hz_ssl_keystore_password_file})
else
   export SECRET_HZ_SSL_KEYSTORE_PASSWORD=hz_ssl_keystore_password
fi

if [ -e "$hz_ssl_truststore_password_file" ]; then
   export SECRET_HZ_SSL_TRUSTSTORE_PASSWORD=$(<${hz_ssl_truststore_password_file})
else
   export SECRET_HZ_SSL_TRUSTSTORE_PASSWORD=hz_ssl_truststore_password
fi

echo "Hazelcast keystore password is - $SECRET_HZ_SSL_KEYSTORE_PASSWORD"

echo "Hazelcast truststore password is - $SECRET_HZ_SSL_TRUSTSTORE_PASSWORD"

if [ -e "$stream_truststore_password_file" ]; then
   export SECRET_STREAM_TRUSTSTORE_PASSWORD=$(<${stream_truststore_password_file})
else
   export SECRET_STREAM_TRUSTSTORE_PASSWORD=stream_truststore_password
fi

echo "Stream truststore password is - $SECRET_STREAM_TRUSTSTORE_PASSWORD"

if [ -e "$stream_keystore_password_file" ]; then
   export SECRET_KEY_TRUSTSTORE_PASSWORD=$(<${stream_keystore_password_file})
else
   export SECRET_KEY_TRUSTSTORE_PASSWORD=stream_keystore_password
fi

echo "Stream keystore password is - $SECRET_KEY_TRUSTSTORE_PASSWORD"

if [ -e "$stream_jaas_config_file" ]; then
   export SECRET_STREAM_JAAS_CONFIG=$(<${stream_jaas_config_file})
else
   export SECRET_STREAM_JAAS_CONFIG=stream_jaas_config
fi

echo "Stream jaas config is - $SECRET_STREAM_JAAS_CONFIG"

if [ -e "$db_username_file" ]; then
   export SECRET_DB_USERNAME=$(<${db_username_file})
else
   export SECRET_DB_USERNAME=postgres_user
fi

if [ -e "$db_password_file" ]; then
   export SECRET_DB_PASSWORD=$(<${db_password_file})
else
   export SECRET_DB_PASSWORD=postgres_pass
fi

echo "Database Username is - $SECRET_DB_USERNAME"

echo "Database Password is - $SECRET_DB_PASSWORD"

if [ -e "$pega_diagnostic_username_file" ]; then
   export SECRET_PEGA_DIAGNOSTIC_USER=$(<${pega_diagnostic_username_file})
else
   export SECRET_PEGA_DIAGNOSTIC_USER=tomcat_user
fi
if [ -e "$pega_diagnostic_password_file" ]; then
   export SECRET_PEGA_DIAGNOSTIC_PASSWORD=$(<${pega_diagnostic_password_file})
else
   export SECRET_PEGA_DIAGNOSTIC_PASSWORD=tomcat_pass
fi

echo "Pega Diagnostic User is - $SECRET_PEGA_DIAGNOSTIC_USER"

echo "Pega Diagnostic Password is - $SECRET_PEGA_DIAGNOSTIC_PASSWORD"

if [ -e "$custom_artifactory_username_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_USERNAME=$(<${custom_artifactory_username_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_USERNAME=artifactory_basic_user
fi

if [ -e "$custom_artifactory_password_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_PASSWORD=$(<${custom_artifactory_password_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_PASSWORD=artifactory_basic_auth_password
fi

echo "Artifactory basic authentication Username is - $SECRET_CUSTOM_ARTIFACTORY_USERNAME"

echo "Artifactory basic authentication Password is - $SECRET_CUSTOM_ARTIFACTORY_PASSWORD"

if [ -e "$custom_artifactory_apikey_header_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER=$(<${custom_artifactory_apikey_header_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER=artifactory_apikey_header
fi

if [ -e "$custom_artifactory_apikey_file" ]; then
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY=$(<${custom_artifactory_apikey_file})
else
   export SECRET_CUSTOM_ARTIFACTORY_APIKEY=artifactory_apikey
fi

echo "Artifactory apikey authentication header is - $SECRET_CUSTOM_ARTIFACTORY_APIKEY_HEADER"

echo "Artifactory apikey authentication apikey value is  - $SECRET_CUSTOM_ARTIFACTORY_APIKEY"

echo "Starting -- Catalina.sh"

