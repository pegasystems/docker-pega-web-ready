Pega Docker Image
===========

This project is a slim version of pega-web docker image that runs pega 8 platform.


# Usability note

Although this code supports running Pega8 in a tomcat based docker container, it does not mean that Pega8 can be used in a docker container clustering environment as is, such as Docker Swarm and Kubernetes.

# Using this image

The image itself is not runnable directly because it does not come with the Pega 8
web applications.  Therefore you must use this image as a base to construct an 
executable Docker image.

## Constructing your image

The simplest way to use this image is to create your own Dockerfile with contents similar to the example below and 
extract the Pega distribution to the same directory as the Dockerfile.  It is recommended that this is done on a Linux system to retain proper file permissions.  Replace the source paths with the actual paths to the Pega 8 software libraries and specify a valid JDBC driver for your target database.

    FROM pegasystems/docker-pega-web-ready
    
    # Expand prweb to target directory
    COPY archives/prweb.war /opt/pega/prweb.war
    RUN unzip -q -d /opt/pega/prweb /opt/pega/prweb.war

    # Make jdbc driver available to tomcat applications
    COPY /path/to/jdbcdriver.jar /usr/local/tomcat/lib/

Build the image using the following command:

    docker build -t pega8-tomcat .

Upon successful completion of the above command, you will have a Docker
image that is registered in your local registry named pega8-tomcat:latest
and that you can view using the `docker images` command

# Customizations

**JDK and Tomcat**

Currently the DockerFile extends the base image `tomcat:9-jre11` . This has been tested internally and works fine.
You can change this to use your preferred Tomcat base image. However this should be thoroughly tested and verfied at your end.There may be some compatibility issue on changing the base image.

**Using environment variables**

You can make adjustments by overriding environmental variables
```bash
$ docker run -e "DB_HOST=55.55.55.1" -e "DB_PORT=1234" <image name>[:tags]
```

Kafka data is saved to `/kafkadata` in the docker container. To persist the data, create a volume and mount it

## Environmental variables

**JDBC Driver**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| JDBC_DRIVER_URI              |                                  | https://jdbc.postgresql.org/download/postgresql-42.1.1.jre7.jar |
| JDBC_DRIVER_URI_USERNAME     |                                  |                |
| JDBC_DRIVER_URI_PASSWORD     |                                  |                |


**Global database variables**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| DB_USERNAME                  |                                  | postgres       |
| DB_PASSWORD | | postgres |
| DB_HOST | | localhost |
| DB_PORT | | 5432 |
| DB_NAME | | postgres |

**JDBC connection string**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| JDBC_CLASS | | org.postgresql.Driver |
| JDBC_DB_TYPE | | postgresql  |
| JDBC_URL_PREFIX | | //  |
| JDBC_URL_SUFFIX | |  |
| JDBC_MIN_ACTIVE | | 50  |
| JDBC_MAX_ACTIVE | | 250 |
| JDBC_MIN_IDLE | | 10 |
| JDBC_MAX_IDLE | | 50 |
| JDBC_MAX_WAIT | | 30000 |
| JDBC_INITIAL_SIZE | | 50 |
| JDBC_VALIDATION_QUERY | | SELECT 1 |

**Rule & data schema**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| RULES_SCHEMA | | rules |
| DATA_SCHEMA | | data |


**Customize the tomcat runtime**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| MAX_THREADS | | 300 |
| JAVA_OPTS | | |
| INITIAL_HEAP | | 2048m |
| MAX_HEAP | | 4096m |
| INDEX_DIRECTORY | | NONE |
| HEAP_DUMP_PATH | | /heapdumps |
| NODE_ID | | "NONE" |
| CONFIG_DIRECTORY | | /config |

**Remote JMX support**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| JMX_PORT | | 9001 |
| JMX_SERVER_HOSTNAME | | 127.0.0.1 |

**DDS/Cassandra settings**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| CASSANDRA_CLUSTER | whether to enable external cassandra | false |
| CASSANDRA_NODES | comma separated list of nodes (e.g. `10.20.205.26,10.20.205.233`) | |
| CASSANDRA_PORT | cql port | 9042 |
| CASSANDRA_USERNAME | username | dnode_ext |
| CASSANDRA_PASSWORD | password | dnode_ext |

