Pega Docker Image
===========

Pega Platform is a distributed web application for customer engagement, customer service, and digital process automation. A Pega deployment consists of a number of containers connecting to a Database and any other required backing services.  The Pega database contains business rule logic that must be preloaded with an installer for the containers to successfully start.  For more information and instructions on how to get started with a container based deployment of Pega, see [Pega's Cloud Choice documentation](https://docs.pega.com/bundle/platform/page/platform/deployment/client-managed-cloud/containerized-deployments-kubernetes.html).

[![Docker Image Build](https://github.com/pegasystems/docker-pega-web-ready/actions/workflows/docker-build.yml/badge.svg?branch=master)](https://github.com/pegasystems/docker-pega-web-ready/actions/workflows/docker-build.yml) [![Docker Image](https://img.shields.io/docker/pulls/pegasystems/pega)][pegasystems/pega]

# Using this image

Pega offers a publicly available Pega runtime Docker image which includes the prweb.war file, but does not contain Pega rules - for details, see [pegasystems/pega on DockerHub][pegasystems/pega] and [Pega-provided Docker images](https://docs.pega.com/bundle/platform/page/platform/deployment/client-managed-cloud/pega-docker-images-manage.html). Pega builds the `pegasystems/pega` image from a [pegasystems/pega-ready](https://hub.docker.com/r/pegasystems/pega-ready) Docker image, a base image that contains an OS (Ubuntu Linux), a Java implementation (Adoptium Temurin JDK11 or JDK17), and an application server (Apache Tomcat), and that is customized with Pega-specific configurations. You can use the `pegasystems/pega-ready` Dockerfile code to customize and build your own web-ready image and then extend it with the Pega .war file of your choice.

Docker images provided by Pegasystems are validated and supported by [Pega Support](https://community.pega.com/support).

## Image customizations

If you do not want to use the Pega-provided Docker image because, for example, you need a customized base image with your preferred OS and JDK enforced by a corporate standard, you can copy this repository and build your own pega-web-ready image based on your preferred base image. When making customizations for your environment, check the [Pega Platform Support Guide Resources](https://community.pega.com/knowledgebase/articles/pega-platform-support-guide-resources) to verify that those changes are supported by your Pega Platform version. 

**Important:** If you choose to build your own image, Pega will continue to offer support for Pega Platform, but problems that arise from your custom image are not the responsibility of Pegasystems.

To build a custom pega-web-ready image using your preferred OS and JDK, perform the following actions:

1. Ensure that the base image you selected has $CATALINA_HOME set to the correct Tomcat location.
   
2. Create a Dockerfile for your custom pega-web-ready image using your base image and the open-source pega-web-ready Dockerfile code.

For more information, see [pegasystems/docker-pega-web-ready/Dockerfile](Dockerfile).

**Note:** You can add any extra environment variables needed in the Dockerfile as per your use-case.

3. Use the following command to build the custom pega-web-ready image using the base image as an argument.

     ```bash
        $ docker build --build-arg BASE_TOMCAT_IMAGE=<BASE_IMAGE> -t <IMAGE_NAME> .
     ```

The system then builds your custom pega-web-ready Docker image.

### Additional Instructions for Fedora based OS.

Pega builds images on Ubuntu, which is Debian-based. If you want to build the Pega web-ready image using a Fedora-based OS, such as RHEL or CentOS,
some of the commands used in the Dockerfile will not work.

Debian uses `apt-get` as package manager, whereas Fedora uses `yum` or `dnf`, therefore you need to replace the `apt-get` references in the Dockerfile with `yum` or `dnf` 
depending on the base image selected.

For example, in the following section of the Dockerfile:

```bash
# Fetches the packages and latest versions.
RUN apt-get update && \
    apt-get install -y gpg && \
    rm -rf /var/lib/apt/lists/*
```

You must replace the `apt-get` package manager with `yum` or `dnf` depending on which package manager is supported in the OS of your choice.


```bash
# Fetches the packages and latest versions.
RUN yum -y update && \
    yum -y install gpg
```

Additionally, you must comment out the following line in the Dockerfile. This command is not intended for Fedora-based OS, and it might impact the OS functionality if used.
```bash
RUN apt-get autoremove --purge -y gpg
```
Important additional notes when building your Pega web-ready image with a Fedora-based OS
1. The `yum/dnf` update command contacts enabled mirror repositories to fetch the packages and their latest versions. 
   For `yum`, you can configure the repositories in the /etc/yum.repos.d directory. Ensure that these repositories are reachable within the Docker host network.
2. If you build an image using `RHEL`, the `yum/dnf` update command attempts to contact Red Hat repositories, so you must confirm your Red Hat identity using subscription-manager to connect to the Red Hat repositories.
   For more details, see https://access.redhat.com/solutions/253273.
3. `Curl` is required for downloading several jars in the Dockerfile at the build time. As a best practice, download curl lib or any other similar utility if it is not part of your base image.
    If you use some alternate tool for curl, change the curl reference accordingly. Alternatively, you can also include the required jars in the base image.


## User access and control considerations for this image

Pega provides this *web-ready* Docker image with built-in user privileges - pegauser:pegauser (9001:9001) which allows you to set default, limited user access policies, so file system access can be controlled by non-root users who deploy the image. The image only provides required file access to pegauser:pegauser. When you build your pega deployment Docker image from this *web-ready*, you should consider adding any user access and control restrictions within the image such as required roles ot priveleges for file or directory access and ownership. 

## Building a deployable Docker image using this *web-ready* image

For clients who need to build their own deployment image, Pega recommends building your Pega image using your own Dockerfile with contents similar to the example below and specifying the .war file from the Pega distribution kit. You may also specify a database driver as shown in the example. It is a best practice to build this image on a Linux system to retain proper file permissions. Replace the source paths with the actual paths to the Pega Infinity software libraries and specify a valid JDBC driver for your target database to bake it in.

To build the Pega image on JDK 11, use `pegasystems/pega-ready:3-jdk11` as the base image.
To build the Pega image on JDK 17, use `pegasystems/pega-ready:3-jdk17` as the base image.
Currently, the `latest` tag points to the Pega image on JDK 17, but it may point to later versions in the future, so as a best practice, use tags that specify the version you want to deploy.

```Dockerfile
FROM busybox AS builder

# Expand prweb to target directory
COPY /path/to/prweb.war /prweb.war
RUN mkdir prweb
RUN unzip -q -o prweb.war -d /prweb

# Building the Pega image on JDK 11. To use images on JDK 17, use the tag 3-jdk17.
FROM pegasystems/pega-ready:3-jdk11 

# Copy prweb to tomcat webapps directory
COPY --chown=pegauser:root --from=builder /prweb ${CATALINA_HOME}/webapps/prweb

RUN chmod -R g+rw   ${CATALINA_HOME}/webapps/prweb

# Make a jdbc driver available to tomcat applications
COPY --chown=pegauser:root /path/to/jdbcdriver.jar /opt/pega/lib/

RUN chmod g+rw ${CATALINA_HOME}/webapps/prweb/WEB-INF/classes/prconfig.xml
RUN chmod g+rw ${CATALINA_HOME}/webapps/prweb/WEB-INF/classes/prlog4j2.xml
```

Build the image using the following command:

```bash
docker build -t pega-tomcat .
```

Since this image uses a secure base image, it doesn't include all the packages in the environment. Therefore use the multi-stage docker build to include only unzipped packages in the final image to reduce the risk of vulnerabilities. 
Upon successful completion of the above command, you will have a Docker image that is registered in your local registry named pega-tomcat:latest, which you can view using the `docker images` command.

## Running the image

You must use an orchestration tool to run Pega applications using containers. Pega provides support for deployments on Kubernetes using either Helm charts or direct yaml files.  You can find the source code for the deployment scripts in the [pega-helm-charts](https://github.com/pegasystems/pega-helm-charts) repository. For information about deploying Pega Platform on a client managed cloud, see the [Cloud Choice](https://community.pega.com/knowledgebase/articles/cloud-choice) community article.

## Mount points

Mount points are used to link a directory within the Docker container to a durable location on a filesystem. For complete information, see the Docker documentation, [bind mounts](https://docs.docker.com/v17.09/engine/admin/volumes/bind-mounts/).

Mount point 	| Purpose
--- 			| ---
`/opt/pega/kafkadata` 	| Used to persist Kafka data when you run stream nodes.
`/heapdumps` 	| Used as the default output directory when you generate a heapdump.
`/search_index`	| Used to persist a search index when the node hosts searched.

## Environment variables

You customize your docker image by overriding environmental variables using the -e Docker flag.
```bash
$ docker run -e "var_1=foo" -e "var_2=bar" <image name>[:tags]
```

### Database connection

Specify your required settings for your connection to the database where Pega will be installed.

Name 				| Purpose 	| Default
--- 				| --- 		| ---
JDBC_DRIVER_URI 	| Download (curl) the specified database driver.  If you do not specify a driver to download, you must embed the driver into your Docker image.  See *Constructing Your Image* for more information on baking a driver in. |
JDBC_URL 			| Specify the JDBC url to connect to your database. |
JDBC_CLASS 			| Specify the JDBC driver class to use for your database. | `org.postgresql.Driver`
DB_USERNAME 		| Specify the username to connect to your database. |
DB_PASSWORD 		| Specify the password to connect to your database. |
RULES_SCHEMA 		| Specify the rules schema for your database. | `rules`
DATA_SCHEMA 		| Specify the data schema for your database. | `data`
CUSTOMERDATA_SCHEMA | If configured in your database, set the customer data schema for your database. If you do not provide a value, this setting defaults to `dataSchema`. |

### Secured Custom artifactory settings used for downloading JDBC driver

If you use a secured custom artifactory to manager your JDBC driver, provide the basic authentication credentials or the API key authentication details to satisfy your custom artifactory authentication mechanism.

Name 						                | Purpose 	                                                                             | Default
--- 						                | --- 		                                                                             | ---
CUSTOM_ARTIFACTORY_USERNAME                 | Custom artifactory basic authentication username.                                      |
CUSTOM_ARTIFACTORY_PASSWORD                 | Custom artifactory basic authentication password.                                      |
CUSTOM_ARTIFACTORY_APIKEY_HEADER            | Custom artifactory dedicated APIKey authentication header name.                        |
CUSTOM_ARTIFACTORY_APIKEY                   | Custom artifactory APIKey value for APIKey authentication.                             |
ENABLE_CUSTOM_ARTIFACTORY_SSL_VERIFICATION  | Sets ssl verification when downloading JDBC driver using curl from custom artifactory. | `false`

### JDBC connection examples
See the following examples for specifying the database and type of driver used for your connection.

#### PostgreSQL
```bash
JDBC_URL=jdbc:postgresql://YOUR_DB_HOST:5432/YOUR_DB_NAME
JDBC_CLASS=org.postgresql.Driver
```

#### Oracle
```bash
JDBC_URL=jdbc:oracle:thin:@//YOUR_DB_HOST:1521/YOUR_DB_NAME
JDBC_CLASS=oracle.jdbc.OracleDriver
```

#### Microsoft SQL Server
```bash
JDBC_URL=jdbc:sqlserver://YOUR_DB_HOST:1433;databaseName=YOUR_DB_NAME;selectMethod=cursor;sendStringParametersAsUnicode=false
JDBC_CLASS=com.microsoft.sqlserver.jdbc.SQLServerDriver
```

For a complete list of supported relational databases, see the [Pega Platform Support Guide](https://community.pega.com/knowledgebase/documents/platform-support-guide). 

### Advanced JDBC configuration

You can specify a variety settings for your connection to the database where Pega will be installed.

Name 						| Purpose 	| Default
--- 						| --- 		| ---
JDBC_MAX_ACTIVE 			| The maximum number of active connections that can be allocated from this pool at the same time. | `75`
JDBC_MIN_IDLE 				| The minimum number of established connections that should be kept in the pool at all times. | `3`
JDBC_MAX_IDLE 				| The maximum number of connections that should be kept in the pool at all times. | `25`
JDBC_MAX_WAIT 				| The number of milliseconds that the database connection pool will wait (when there are no available connections) for a connection to be returned before throwing an exception. | `10000`
JDBC_INITIAL_SIZE 			| The initial number of database connections that are created when the pool is started. | `0`
JDBC_CONNECTION_PROPERTIES 	| The database connection pool properties that deploying sends to the JDBC driver when creating new database connections. Format of the string must be `[propertyName=property;]*`  |
JDBC_TIME_BETWEEN_EVICTIONS | The number of milliseconds to sleep between runs of the idle connection validation/cleaner thread. | `30000`
JDBC_MIN_EVICTABLE_IDLE_TIME| The number of milliseconds that an object is allowed to sit idle in the database connection pool before it is eligible for eviction. | `60000`

### Pega customization

You can specify a variety settings for nodes in your deployment.

Name 						| Purpose 	| Default
--- 						| --- 		| ---
NODE_TYPE 					| Specify a node type or classification to specialize the processing within this container.  for more information, see  [Node types for on-premises environments](https://community.pega.com/sites/default/files/help_v83/procomhelpmain.htm#engine/node-classification/eng-node-types-ref.htm). |
PEGA_DIAGNOSTIC_USER 		| Set a Pega diagnostic username to download log files. |
PEGA_DIAGNOSTIC_PASSWORD 	| Set a secure Pega diagnostic username to download log files. |
NODE_TIER                 | Specify the display name of the tier to which you logically associate this node. |
WEB_XML_SNIPPET | Specify additional text to be inserted before the closing tag of web.xml. This can be used to add JMS Resource References. |

### Customize the Tomcat runtime

You can specify a variety settings for the Tomcat server running in your deployment.

Name 			| Purpose 	| Default
--- 			| --- 		| ---
PEGA_APP_CONTEXT_PATH   | The application context path that Tomcat uses to direct traffic to the Pega application | prweb
PEGA_DEPLOYMENT_DIR   | The location of the Pega app deployment | /usr/local/tomcat/webapps/prweb
JAVA_OPTS 		| Specify any additional parameters that should be appended to the `java` command. |
INITIAL_HEAP 	| Specify the initial size (`Xms`) of the java heap. | `2048m`
MAX_HEAP 		| Specify the maximum size (`Xmx`) of the java heap. | `4096m`
HEAP_DUMP_PATH 	| Specify a location for a heap dump using `XX:HeapDumpPath` | `/heapdumps`

### Cassandra settings

For Pega Platform deployments running Pega Decisioning, you must specify how to connect to your organization's existing Cassandra service by using parameters to manage the connection to the service.

Name | Purpose | Default
---  |---      |---
CASSANDRA_CLUSTER | Enable a connection to your organization's Cassandra service. | `false`
CASSANDRA_NODES | Specify A comma separated list of hosts in your Cassandra service cluster (for example, `10.20.205.26,10.20.205.233`). |
CASSANDRA_PORT | Specify the TCP port to connect to your Cassandra service cluster. | `9042`
CASSANDRA_USERNAME | Specify the plain text username for authentication with your Cassandra service cluster. For better security, avoid plain text usernames and leave this parameter blank; then include the username in an external secrets manager with the key CASSANDRA_USERNAME. |
CASSANDRA_PASSWORD | Specify the plain text password for authentication with your Cassandra service cluster. For better security, avoid plain text passwords and leave this parameter blank; then include the password in an external secrets manager with the key CASSANDRA_PASSWORD. |
CASSANDRA_CLIENT_ENCRYPTION | Enable encryption of traffic between Pega Platform instance and your organization's Cassandra service. | `false`
CASSANDRA_CLIENT_AUTH | Enable authentication of client certificates in the encrypted connection to your organization's Cassandra service. | `false`
CASSANDRA_CLIENT_ENCRYPTION_STORE_TYPE | Specify the archive file format in which Cassandra client encryption keys are held. | `JKS`
CASSANDRA_TRUSTSTORE | Specify the path to the truststore file which contains trusted third party certificates that will be used in Cassandra client encryption. |
CASSANDRA_TRUSTSTORE_PASSWORD | Specify the plain text password for the Cassandra client encryption truststore file. For better security, avoid plain text passwords and leave this parameter blank; then include the password in an external secrets manager with the key CASSANDRA_TRUSTSTORE_PASSWORD. |
CASSANDRA_KEYSTORE | Specify the path to the keystore file which contains keys and certificates that will be used in Cassandra client encryption to establish secure connection. |
CASSANDRA_KEYSTORE_PASSWORD | Specify the plain text password for the Cassandra client encryption keystore file. For better security, avoid plain text passwords and leave this parameter blank; then include the password in an external secrets manager with the key CASSANDRA_KEYSTORE_PASSWORD. |
CASSANDRA_ASYNC_PROCESSING_ENABLED | Enable asynchronous processing of records in DDS Dataset save operation. Failures to store individual records will not interrupt Dataset save operations. | `false`
CASSANDRA_KEYSPACES_PREFIX | Specify a prefix to use when creating Pega-managed keyspaces in Cassandra. |
CASSANDRA_EXTENDED_TOKEN_AWARE_POLICY | Enable an extended token aware policy for use when a Cassandra range query runs. When enabled this policy selects a token from the token range to determine which Cassandra node to send the request. Before you can enable this policy, you must configure the token range partitioner. | `false`
CASSANDRA_LATENCY_AWARE_POLICY | Enable a latency awareness policy, which collects the latencies of the queries for each Cassandra node and maintains a per-node latency score (an average). | `false`
CASSANDRA_CUSTOM_RETRY_POLICY | Enable the use of a customized retry policy for your Pega Platform deployment for Pega Platform ’23 and earlier releases. After you enable this policy in your deployment configuration, the deployment retries Cassandra queries that time out. Configure the number of retries using the dynamic system setting (DSS): dnode/cassandra_custom_retry_policy/retryCount. The default is 1, so if you do not specify a retry count, timed out queries are retried once. | false
CASSANDRA_CUSTOM_RETRY_POLICY_ENABLED | Use this parameter in Pega Platform '24 and later instead of CASSANDRA_CUSTOM_RETRY_POLICY. Configure the number of retries using the CASSANDRA_CUSTOM_RETRY_POLICY_COUNT property.| false
CASSANDRA_CUSTOM_RETRY_POLICY_COUNT | Specify the number of retry attempts when CASSANDRA_CUSTOM_RETRY_POLICY is true. For Pega Platform '23 and earlier releases use the dynamic system setting (DSS): dnode/cassandra_custom_retry_policy/retryCount. | 1
CASSANDRA_SPECULATIVE_EXECUTION_POLICY | Enable the speculative execution policy for retrieving data from your Cassandra service for Pega Platform '23 and earlier releases. When enabled, the Pega Platform will send a query to multiple nodes in your Cassandra service and process the first query response. This provides lower perceived latencies for your deployment, but puts greater load on your Cassandra service. Configure the speculative execution delay and max executions using the following dynamic system settings (DSS): dnode/cassandra_speculative_execution_policy/delay and dnode/cassandra_speculative_execution_policy/max_executions. | false
CASSANDRA_SPECULATIVE_EXECUTION_POLICY_ENABLED | Use this parameter in Pega Platform '24 and later instead of CASSANDRA_SPECULATIVE_EXECUTION_POLICY. Configure the speculative execution delay and max executions using the CASSANDRA_SPECULATIVE_EXECUTION_DELAY and CASSANDRA_SPECULATIVE_EXECUTION_MAX_EXECUTIONS properties. | false
CASSANDRA_SPECULATIVE_EXECUTION_DELAY | Specify the delay in milliseconds before speculative executions are made when CASSANDRA_SPECULATIVE_EXECUTION_POLICY is true. For Pega Platform '23 and earlier releases use the dynamic system setting (DSS): dnode/cassandra_speculative_execution_policy/delay. | 100
CASSANDRA_SPECULATIVE_EXECUTION_MAX_EXECUTIONS | Specify the maximum number of speculative execution attempts when CASSANDRA_SPECULATIVE_EXECUTION_POLICY is true. For Pega Platform '23 and earlier releases use the dynamic system setting (DSS): dnode/cassandra_speculative_execution_policy/max_executions. | 2
CASSANDRA_JMX_METRICS_ENABLED | Enable reporting of DDS SDK metrics to a Java Management Extension (JMX) format for use by your organization to monitor your Cassandra service. Setting this property `false` disables metrics being exposed through the JMX interface; disabling also limits the metrics being collected using the DDS landing page. | `true`
CASSANDRA_CSV_METRICS_ENABLED | Enable reporting of DDS SDK metrics to a Comma Separated Value (CSV) format for use by your organization to monitor your Cassandra service. If you enable this property, use the Pega Platform DSS: dnode/ddsclient/metrics/csv_directory to customize the filepath to which the deployment writes CSV files. By default, after you enable this property, CSV files will be written to the Pega Platform work directory. | `false`
CASSANDRA_LOG_METRICS_ENABLED | Enable reporting of DDS SDK metrics to your Pega Platform logs. | `false`
CASSANDRA_LOCAL_DATACENTER | Local Cassandra datacenter in a multi-datacenter Cassandra cluster. | 
CASSANDRA_DATACENTERS | List of all Cassandra datacenters in a multi-datacenter Cassandra cluster. |


### Hazelcast settings

The clustering used in a Pega environment is powered by a technology called `Hazelcast`. Hazelcast can be used in an embedded mode with no additional configuration required.  Some larger deployments of more than 20 Pega containers may start to benefit from improved performance and stability of running Hazelcast in a dedicated ReplicaSet. For more information about deploying Pega with Hazelcast as an external server, see the Helm charts and the Pega Community documentation.

Name 				| Purpose 		| Default
--- 				| --- 			| ---
HZ_CLIENT_MODE | Enables client mode for infinity  | `false`
HZ_VERSION | Hazelcast service version.  |
HZ_DISCOVERY_K8S | Indicates infinity client will use K8s discovery plugin to look for hazelcast nodes |
HZ_CLUSTER_NAME| Hazelcast cluster name |
HZ_SERVER_HOSTNAME| Hazelcast server hostname |
HZ_CS_AUTH_USERNAME | Hazelcast username for authentication |
HZ_CS_AUTH_PASSWORD | Hazelcast password for authentication |
HZ_SSL_ENABLED | Set to true to enable SSL between the Clustering Service and Pega Platform. | false
HZ_SSL_PROTOCOL | The SSL protocol for the Clustering Service. For example, TLS. |
HZ_SSL_CUSTOM_CLASS | SSL context factory class fully qualified name | com.pega.hazelcast.v5.nio.ssl.BasicSSLContextFactory
HZ_SSL_KEY_STORE_NAME | SSL keystore name |
HZ_SSL_KEYSTORE_PASSWORD | SSL keystore password |
HZ_SSL_ALGO | SSL algorithm name |
HZ_SSL_TRUST_STORE_NAME | SSL truststore name |
HZ_SSL_TRUSTSTORE_PASSWORD | SSL truststore password |
HIGHLY_SECURE_CRYPTO_MODE_ENABLED | Set to true to enable highly secure encryption mode that complies with NIST SP 800-53 and NIST SP 800-131. | false

### Search and Reporting Service settings

Search and reporting functionality within a Pega environment is provided by the Search and Reporting Service (SRS). SRS operates as an external service and can be deployed in a cluster. For comprehensive guidance on deploying Pega with SRS as an external service, refer to the Helm charts and the official Pega Community documentation.

Name                    | Purpose                                                  | Default
---                     |----------------------------------------------------------| ---
SRS_TRUSTSTORE_PASSWORD | Password for the truststore to use in mTLS communication. | 
SRS_KEYSTORE_PASSWORD   | Password for the keystore to use in mTLS communication.  |

# Contributing

This is an open source project and contributions are welcome.  Please see the [contributing guidelines](./CONTRIBUTING.md) to get started.

[pegasystems/pega]: https://hub.docker.com/r/pegasystems/pega
[Node classification]: https://community.pega.com/sites/default/files/help_v83/procomhelpmain.htm#engine/node-classification/eng-node-types-ref.htm
