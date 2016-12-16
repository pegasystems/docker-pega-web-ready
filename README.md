# Pega7 Tomcat docker container

This project produces a docker image that can be used as a base image for
 customers to create a complete docker image for running Pega7.  

This image is based on Tomcat 7 which itself is based on OpenJDK's Java 7 image. 

Features supported are :

* PR Web application container configuration (port 8080)
* PR System Management application container configuration (port 8091)
* Remote JMX management support (port 9001)

# How to use this image

The image itself is not runnable directly as it does not come with the Pega7
 web applications.  Therefore you must use this as a base image to construct an 
 executable docker image.

## Construct your image

The simplest use is to create your own Dockerfile with contents like below,
 replacing the source paths with actual paths to Pega7 software libraries
 and a valid JDBC driver for your target database.

    FROM pegasystems:pega7-tomcat-ready
    
    # Expand prweb to target directory
    COPY /path/to/prweb.war /opt/pega/prweb.war
    RUN unzip -q -d /opt/pega/prweb /opt/pega/prweb.war
    
    # Expand pr sys managment to target directory
    COPY /path/to/prsysmgmt.war /opt/pega/prsysmgmt.war
    RUN unzip -q -d /opt/pega/prsysmgmt /opt/pega/prsysmgmt.war
     
    # Make jdbc driver available to tomcat applications
    COPY /path/to/jdbcdriver.jar /usr/local/tomcat/lib/

Build the image:

    docker build -t pega7-tomcat .

Upon successful completion of the above command, you will now have a docker
image registered in your local registry and can be seen via the `docker images` command.

## Run the image

The built image will require connectivity to a database which must already be 
 available and seeded with the appropriate rulebase via the Pega7 standard installation
 utility.

    docker run -d -P --name pega7 -e DB_HOST=<host> ... pega7-tomcat

In the above command, the `-d`flag  tells docker to run this program as a daemon process in 
 the background.  The `-P` flag tells docker to expose all ports in the image to dynamically
 selected ports on the host machine.  The `-e` flag is a declaration of an environment
 variable.  See the [Dockerfile](Dockerfile) for the list of exposed variables.

If you are planning on running Pega7 

# Accessing Pega7

Once the image is running, you can connect to the Pega7 web application via the exposed bound
port.  To find this port (assuming you had them dynamically assigned as above), you can run 
the `docker ps` command to print out the port bindings.  Look for the 8080 port and connect to
it from your web browser at `http://host:port/prweb`.

To connect to the PR System Management application, you would do the same as above but look for
the port mapped to 8091 and connect to it via a web browser at `http://host:port/prsysmgmt`. 
The log in credentials are defined in the [tomcat-users.xml](conf/tomcat-users.xml) file and should be overriden by your own file.