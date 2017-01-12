# Pega7 Tomcat docker container

This project produces a docker image that you can use as a base image to create a complete docker image for running Pega7.  

This image is based on Tomcat 7 which is based on OpenJDK's Java 7 image. 

Supported features:

* PR Web application container configuration (port 8080)
* PR System Management application container configuration (port 8090)
* Remote JMX management support (port 9001)

# Using this image

The image itself is not runnable directly because it does not come with the Pega 7
 web applications.  Therefore you must use this image as a base to construct an 
 executable Docker image.

## Constructing your image

The simplest way to use this image is to create your own Dockerfile with contents similar to the example below and 
extract the Pega distribution to the same directory.  Recommend that this is done on a linux system to retain proper
file permissions.  Replace the source paths with the actual paths to the Pega 7 software libraries
 and specify a valid JDBC driver for your target database.

    FROM pegasystems/pega7-tomcat-ready
    
    # Expand prweb to target directory
    COPY archives/prweb.war /opt/pega/prweb.war
    RUN unzip -q -d /opt/pega/prweb /opt/pega/prweb.war
    
    # Expand pr sys managment to target directory
    COPY archives/prsysmgmt.war /opt/pega/prsysmgmt.war
    RUN unzip -q -d /opt/pega/prsysmgmt /opt/pega/prsysmgmt.war
     
    # Make jdbc driver available to tomcat applications
    COPY /path/to/jdbcdriver.jar /usr/local/tomcat/lib/

Build the image using the following command:

    docker build -t pega7-tomcat .

Upon successful completion of the above command, you will have a Docker
image that is registered in your local registry named pega7-tomcat:latest
 and that you can view using the `docker images` command.

## Running the image

The built image requires connectivity to a database that must be 
 available and seeded with the appropriate rule base via the Pega 7 standard installation
 utility.

    docker run -d -P --name pega7 -e DB_HOST=<host> ... pega7-tomcat

In the above command, the `-d`flag  tells docker to run this program as a daemon process in 
 the background.  The `-P` flag tells docker to expose all ports in the image to dynamically
 selected ports on the host machine.  The `-e` flag is a declaration of an environment
 variable.  See the [Dockerfile](Dockerfile) for the list of exposed variables.

# Accessing Pega 7

Use these instructions if you want to run Pega 7.

Once the image is running, you can connect to the Pega 7 web application via the exposed bound
port.  To find this port (assuming you had them dynamically assigned as above), you can run 
the `docker ps` command to print out the port bindings.  Look for the 8080 port and connect to
it from your web browser at `http://host:port/prweb`.

To connect to the PR System Management application, use the 'docker ps' command and look for
the port mapped to 8090 and connect to it via a web browser at `http://host:port/prsysmgmt`. 
The login credentials are defined in the [tomcat-users.xml](conf/tomcat-users.xml) file and should be overridden by your own file.
