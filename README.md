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

# Import prweb to tomcat webapps directory
COPY --from=builder /prweb ${CATALINA_HOME}/webapps/prweb

# Make a jdbc driver available to tomcat applications
COPY /path/to/jdbcdriver.jar ${CATALINA_HOME}/lib/
```

Build the image using the following command:

```bash
docker build -t pega-tomcat .
```

Since this image uses a secure base image, it doesn't include all the packages in the environment. Therefore use multi-stage docker build to include only unzip package in the final image to reduce the risk of vulnerabilities. 
Upon successful completion of the above command, you will have a Docker
image that is registered in your local registry named pega-tomcat:latest
and that you can view using the `docker images` command.

## Running the image

You must use an orchestration tool to run Pega applications using containers. Pega provides support for deployments on Kubernetes using either Helm charts or direct yaml files.  You can find the source code for the deployment scripts in the [pega-helm-charts](https://github.com/pegasystems/pega-helm-charts) repository. For information about deploying Pega Platform on a client-managed cloud, see the [Cloud Choice](https://community.pega.com/knowledgebase/articles/cloud-choice) community article.

## Mount points

Mount points are used to link a directory within the Docker container to a durable location on a filesystem.  See Docker's [bind mounts](https://docs.docker.com/v17.09/engine/admin/volumes/bind-mounts/) documentation for more information.

Mount point 	| Purpose
--- 			| ---
`/kafkadata` 	| Used to persist Kafka's data when running as a stream node.
`/heapdumps` 	| Used as the default output directory when a heapdump is generated.
`/search_index`	| Used to persist a search index when operating as a search node.

## Environment variables

You can make adjustments by overriding environmental variables using the -e Docker flag.
```bash
$ docker run -e "var_1=foo" -e "var_2=bar" <image name>[:tags]
```

### Database connection

Name 				| Purpose 	| Default
--- 				| --- 		| ---
JDBC_DRIVER_URI 	| Download (curl) the specified database driver.  If you do not specify a driver to download, you must embed the driver into your Docker image.  See *Constructing Your Image* for more information on baking a driver in. |
JDBC_URL 			| Specify the JDBC url to connect to your database. |
JDBC_CLASS 			| Specify the JDBC driver class to use for your database. | `org.postgresql.Driver`
DB_USERNAME 		| Specify the username to connect to your database. |
DB_PASSWORD 		| Specify the password to connect to your database. |
RULES_SCHEMA 		| Specify the rules schema for your database. | `rules`
DATA_SCHEMA 		| Specify the data schema for your database. | `data`
CUSTOMERDATA_SCHEMA | If configured, set the customer data schema for your database. Defaults to value of `dataSchema` if not provided. |

### JDBC connection examples

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

### Pega customization

Name 						| Purpose 	| Default
--- 						| --- 		| ---
NODE_TYPE 					| Specify a node type or classification to specialize the processing within this container.  See [Node classification] on the Pega Community for more information. |
PEGA_DIAGNOSTIC_USER 		| Set a Pega diagnostic username to download log files. |
PEGA_DIAGNOSTIC_PASSWORD 	| Set a secure Pega diagnostic username to download log files. |

### Advanced JDBC configuration

Name 						| Purpose 	| Default
--- 						| --- 		| ---
JDBC_MAX_ACTIVE 			| The maximum number of active connections that can be allocated from this pool at the same time. | `250`
JDBC_MIN_IDLE 				| The minimum number of established connections that should be kept in the pool at all times. | `10`
JDBC_MAX_IDLE 				| The maximum number of connections that should be kept in the pool at all times. | `50`
JDBC_MAX_WAIT 				| The maximum number of milliseconds that the pool will wait (when there are no available connections) for a connection to be returned before throwing an exception. | `30000`
JDBC_INITIAL_SIZE 			| The initial number of connections that are created when the pool is started. | `50`
JDBC_CONNECTION_PROPERTIES 	| The connection properties that will be sent to our JDBC driver when establishing new connections. Format of the string must be `[propertyName=property;]*`  | `socketTimeout=90`

### Customize the Tomcat runtime

Name 			| Purpose 	| Default
--- 			| --- 		| ---
MAX_THREADS 	| The max number of active threads in this pool using Tomcat's `maxThreads` setting. | `300`
JAVA_OPTS 		| Specify any additional parameters that should be appended to the `java` command. |
INITIAL_HEAP 	| Specify the initial size (`Xms`) of the java heap. | `2048m`
MAX_HEAP 		| Specify the maximum size (`Xmx`) of the java heap. | `4096m`
HEAP_DUMP_PATH 	| Specify a location for a heap dump using `XX:HeapDumpPath` | `/heapdumps`


### Cassandra settings

Name 				| Purpose 		| Default
--- 				| --- 			| ---
CASSANDRA_CLUSTER	| Enable connection to an external Cassandra cluster | `false`
CASSANDRA_NODES		| A comma separated list of C* nodes (e.g. `10.20.205.26,10.20.205.233`) |
CASSANDRA_PORT		| C* port		| `9042`
CASSANDRA_USERNAME	| C* username	|
CASSANDRA_PASSWORD	| C* password	|

## Image customizations

This Docker image extends the base image `pegasystems/tomcat:9-jdk11`. This has been thoroughly validated. You may choose change this to use your preferred Tomcat base image, however any change should be thoroughly tested and verified. Any problems that arise from changing the base of this image or customizing the contents of the ready image  cannot be supported by Pegasystems.

# Contributing

This is an open source project and contributions are welcome.  Please see the [contributing guidelines](./CONTRIBUTING.md) to get started.

[pegasystems/pega]: https://hub.docker.com/r/pegasystems/pega
[Node classification]: https://community.pega.com/sites/default/files/help_v83/procomhelpmain.htm#engine/node-classification/eng-node-types-ref.htm