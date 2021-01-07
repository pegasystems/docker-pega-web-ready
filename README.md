Pega Docker Image
===========

Pega Platform is a distributed web application for customer engagement, customer service, and digital process automation. A Pega deployment consists of a number of containers connecting to a Database and any other required backing services.  The Pega database contains business rule logic that must be preloaded with an installer for the containers to successfully start.  For more information and instructions on how to get started with a container based deployment of Pega, see [Pega's Cloud Choice documentation](https://community.pega.com/knowledgebase/articles/cloud-choice).

[![Build Status](https://travis-ci.org/pegasystems/docker-pega-web-ready.svg?branch=master)](https://travis-ci.org/pegasystems/docker-pega-web-ready) [![Docker Image](https://img.shields.io/docker/pulls/pegasystems/pega)][pegasystems/pega]


# Using this image

This *ready* Docker image represents one component of a full image you can use to run a Pega node. It is built on top of Tomcat but does not contain the Pega .war file (hence it is *ready* for the .war file - see [pegasystems/pega on DockerHub][pegasystems/pega] for the full image which *includes* the .war file).

## Constructing your image from *pega-ready*

The simplest way to build from this image is to create your own Dockerfile with contents similar to the example below, and specify the .war file from the Pega distribution kit.  You may also specify a database driver as shown in the example.  It's a best practice to build this image on a Linux system to retain proper file permissions.  Replace the source paths with the actual paths to the Pega Infinity software libraries and specify a valid JDBC driver for your target database to bake it in.

```Dockerfile
FROM busybox AS builder

# Expand prweb to target directory
COPY /path/to/prweb.war /prweb.war
RUN mkdir prweb
RUN unzip -q -o prweb.war -d /prweb


FROM pegasystems/pega-ready

# Copy prweb to tomcat webapps directory
COPY --chown=pegauser:root --from=builder /prweb ${CATALINA_HOME}/webapps/prweb

RUN chmod -R g+rw   ${CATALINA_HOME}/webapps/prweb

# Make a jdbc driver available to tomcat applications
COPY --chown=pegauser:root /path/to/jdbcdriver.jar ${CATALINA_HOME}/lib/

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

Specify your required settings for your connection to the database wher Pega will be installed.

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
JDBC_MAX_WAIT 				| The maximum number of milliseconds that the pool will wait (when there are no available connections) for a connection to be returned before throwing an exception. | `30000`
JDBC_INITIAL_SIZE 			| The initial number of connections that are created when the pool is started. | `10`
JDBC_CONNECTION_PROPERTIES 	| The connection properties that will be sent to our JDBC driver when establishing new connections. Format of the string must be `[propertyName=property;]*`  | 

### Pega customization

You can specify a variety settings for nodes in your deployment.

Name 						| Purpose 	| Default
--- 						| --- 		| ---
NODE_TYPE 					| Specify a node type or classification to specialize the processing within this container.  for more information, see  [Node types for on-premises environments](https://community.pega.com/sites/default/files/help_v83/procomhelpmain.htm#engine/node-classification/eng-node-types-ref.htm). |
PEGA_DIAGNOSTIC_USER 		| Set a Pega diagnostic username to download log files. |
PEGA_DIAGNOSTIC_PASSWORD 	| Set a secure Pega diagnostic username to download log files. |
NODE_TIER                 | Specify the display name of the tier to which you logically associate this node. |

### Customize the Tomcat runtime

You can specify a variety settings for the Tomcat server running in your deployment.

Name 			| Purpose 	| Default
--- 			| --- 		| ---
PEGA_APP_CONTEXT_PATH   | The application context path that Tomcat uses to direct traffic to the Pega application | prweb
PEGA_DEPLOYMENT_DIR   | The location of the Pega app deployment | /usr/local/tomcat/webapps/prweb
MAX_THREADS 	| The max number of active threads in this pool using Tomcat's `maxThreads` setting. | `300`
JAVA_OPTS 		| Specify any additional parameters that should be appended to the `java` command. |
INITIAL_HEAP 	| Specify the initial size (`Xms`) of the java heap. | `2048m`
MAX_HEAP 		| Specify the maximum size (`Xmx`) of the java heap. | `4096m`
HEAP_DUMP_PATH 	| Specify a location for a heap dump using `XX:HeapDumpPath` | `/heapdumps`


### Cassandra settings

For Pega Decisioning or Pega Marketing deployments, you can specify how to run Cassandra server by either pointing to an existing deployment or deploy a new instance managed by Pega during your deployment.

Name 				| Purpose 		| Default
--- 				| --- 			| ---
CASSANDRA_CLUSTER	| Enable connection to an external Cassandra cluster | `false`
CASSANDRA_NODES		| A comma separated list of C* nodes (e.g. `10.20.205.26,10.20.205.233`) |
CASSANDRA_PORT		| C* port		| `9042`
CASSANDRA_USERNAME	| C* username	|
CASSANDRA_PASSWORD	| C* password	|


### Hazelcast settings

The clustering used in a Pega environment is powered by a technology called `Hazelcast`. Hazelcast can be used in an embedded mode with no additional configuration required.  Some larger deployments of more than 20 Pega containers may start to benefit from improved performance and stability of running Hazelcast in a dedicated ReplicaSet. For more information about deploying Pega with Hazelcast as an external server, see the Helm charts and the Pega Community documentation.

Name 				| Purpose 		| Default
--- 				| --- 			| ---
HZ_CLIENT_MODE | Enables client mode for infinity  | `false`
HZ_DISCOVERY_K8S | Indicates infinity client will use K8s discovery plugin to look for hazelcast nodes |
HZ_CLUSTER_NAME| Hazelcast cluster name |
HZ_SERVER_HOSTNAME| Hazelcast server hostname |
HZ_CS_AUTH_USERNAME | Hazelcast username for authentication |
HZ_CS_AUTH_PASSWORD | Hazelcast password for authentication |

## Image customizations

This Docker image extends the base image `pegasystems/tomcat:9-jdk11`. This has been thoroughly validated. You may choose change this to use your preferred Tomcat base image, however any change should be thoroughly tested and verified. Any problems that arise from changing the base of this image or customizing the contents of the ready image are not the responsibility of Pegasystems.

# Contributing

This is an open source project and contributions are welcome.  Please see the [contributing guidelines](./CONTRIBUTING.md) to get started.

[pegasystems/pega]: https://hub.docker.com/r/pegasystems/pega
[Node classification]: https://community.pega.com/sites/default/files/help_v83/procomhelpmain.htm#engine/node-classification/eng-node-types-ref.htm
