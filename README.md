Pega Docker Image
===========

This project produces a base Docker image that can be used to create a complete Docker image for running Pega applications using containers.  The Pega .war file is not included in this build.

[![Build Status](https://travis-ci.org/pegasystems/docker-pega-web-ready.svg?branch=master)](https://travis-ci.org/pegasystems/docker-pega-web-ready)


# Using this image

You cannot run the image directly because it does not come with the Pega web application (.war file).  Therefore you must use this image as a base to construct an executable Docker image.

## Constructing your image

The simplest way to use this image is to create your own Dockerfile with contents similar to the example below and extract the Pega distribution to the same directory as the Dockerfile.  It's a best practice to build this image on a Linux system to retain proper file permissions.  Replace the source paths with the actual paths to the Pega Infinity software libraries and specify a valid JDBC driver for your target database.

    FROM pegasystems/pega-ready
    
    # Expand prweb to target directory
    COPY archives/prweb.war ${CATALINA_HOME}/webapps/prweb.war
    RUN unzip -q -o -d ${CATALINA_HOME}/webapps/prweb ${CATALINA_HOME}/webapps/prweb.war && \
    rm -rf ${CATALINA_HOME}/webapps/prweb.war

    # Make jdbc driver available to tomcat applications
    COPY /path/to/jdbcdriver.jar ${CATALINA_HOME}/lib/

Build the image using the following command:

    docker build -t pega-tomcat .

Upon successful completion of the above command, you will have a Docker
image that is registered in your local registry named pega-tomcat:latest
and that you can view using the `docker images` command.

## Running the image

You must use an orchestration tool to run Pega applications using containers. Pega provides support for deployments on Kubernetes using either Helm charts or direct yaml files.  You can find the source code for the deployment scripts in the [pega-helm-charts](https://github.com/pegasystems/pega-helm-charts) repository. For information about deploying Pega Platform on a client-managed cloud, see the [Cloud Choice](https://community.pega.com/knowledgebase/articles/cloud-choice) community article.

## Image customizations

**Base image**

This Docker image extends the base image `tomcat:9-jre11`. This has been thoroughly validated. You may choose change this to use your preferred Tomcat base image, however any change should be thoroughly tested and verfied.

**Using environment variables**

You can make adjustments by overriding environmental variables
```bash
$ docker run -e "DB_HOST=55.55.55.1" -e "DB_PORT=1234" <image name>[:tags]
```

Kafka data is saved to `/kafkadata` in the docker container. To persist the data, create a volume and mount it

### Environment variables

**Database connection**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| JDBC_DRIVER_URI              | Download (curl) the specified database driver.  If you do not specify a driver to download, you must embed the driver into your Docker image.  See *Constructing Your Image* for more information on baking a driver in. | https://jdbc.postgresql.org/download/postgresql-42.1.1.jre7.jar |
| JDBC_URL                     |                                  |                |
| DB_USERNAME                  |                                  |                |
| DB_PASSWORD                  |                                  |                |
| JDBC_CLASS                   |                                  | org.postgresql.Driver |
| RULES_SCHEMA                 |                                  | rules          |
| DATA_SCHEMA                  |                                  | data           |
| CUSTOMERDATA_SCHEMA          |                                  |                |

**Advanced JDBC configuration**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| JDBC_MIN_ACTIVE              |                                  | 50  |
| JDBC_MAX_ACTIVE              |                                  | 250 |
| JDBC_MIN_IDLE                |                                  | 10 |
| JDBC_MAX_IDLE                |                                  | 50 |
| JDBC_MAX_WAIT                |                                  | 30000 |
| JDBC_INITIAL_SIZE            |                                  | 50 |
| JDBC_CONNECTION_PROPERTIES   |                                  | socketTimeout=90 |

**Customize the tomcat runtime**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| MAX_THREADS                  |                                  | 300 |
| JAVA_OPTS                    |                                  | |
| INITIAL_HEAP                 |                                  | 2048m |
| MAX_HEAP                     |                                  | 4096m |
| INDEX_DIRECTORY              |                                  | NONE |
| HEAP_DUMP_PATH               |                                  | /heapdumps |
| NODE_TYPE                    |                                  | |
| NODE_SETTINGS                |                                  | |
| PEGA_DIAGNOSTIC_USER         |                                  | |
| PEGA_DIAGNOSTIC_PASSWORD     |                                  | |

**Cassandra settings**

|  Name                        | Purpose                          | Default        |
| ---------------------------- | -------------------------------- | -------------- |
| CASSANDRA_CLUSTER            | Enable connection to an external Cassandra cluster | false |
| CASSANDRA_NODES              | A comma separated list of C* nodes (e.g. `10.20.205.26,10.20.205.233`) | |
| CASSANDRA_PORT               | C* port                          | 9042 |
| CASSANDRA_USERNAME           | C* username                      |  |
| CASSANDRA_PASSWORD           | C* password                      |  |

