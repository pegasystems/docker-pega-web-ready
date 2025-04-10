# Build a custom pega-web-ready Docker image using your preferred OS and JDK

Prerequisites:
• You have a basic knowledge of Docker and Linux commands.
• You have a base Docker image with your preferred OS and JDK.
• The base image you selected must have $CATALINA_HOME set to the correct tomcat location.

Pega provides a pega-web-ready Docker image using Tomcat 9 and JDK 11 as a base image. For more information about the pega-web-ready Docker image, see `pegasystems/docker-pega-web-ready`
To build a custom pega-web-ready image using your preferred OS and JDK, perform the following actions:

1. Create a Dockerfile for your custom pega-web-ready image using your base image and the open-source pega-web-ready Dockerfile code. 
   For more information, see pegasystems/docker-pega-web-ready/Dockerfile.
   Note: You can add any extra environment variables needed in the Dockerfile as per your use-case.
         The base image selected should have $CATALINA_HOME and $JAVA_HOME set to the correct tomcat and jdk locations.

2. Use the following command to build the custom pega-web-ready image using the base image as an argument.
     ```bash
        docker build --build-arg BASE_TOMCAT_IMAGE=<BASE_IMAGE> -t <IMAGE_NAME> .
     ```

The system then builds your custom pega-web-ready Docker image.

 ### Special Instructions for Fedora based OS.

If you are building an image using OS like RHEL/CentOS which are Fedora based, some of the commands used in Dockerfile will not work.
Fedora uses `yum` as package manager and Debian uses `apt-get` as package manager.

Pega shipped images are built on Ubuntu which is debian based.
Hence in the Dockerfile, it is needed to replace the apt-get references with yum.

In Dockerfile, in the section where we download necessary jars, we are using apt-get and this has to be replaced with yum. Look for text `# download necessary jars` in the Dockerfile.
Please see below reference how to replace the apt-get commands with yum commands.


```bash
#download necessary jars
RUN yum -y update && \
yum install gpg && \
rm -rf /var/lib/apt/lists/* && \
mkdir -p /opt/pega/prometheus && \
mkdir -p /opt/pega/bcfips && \
curl -sL -o /opt/pega/prometheus/jmx_prometheus_javaagent.jar https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar && \
curl -sL -o /tmp/jmx_prometheus_javaagent-0.18.0.jar.asc https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar.asc && \
gpg --import /keys/prometheus.asc && \
gpg --verify /tmp/jmx_prometheus_javaagent-0.18.0.jar.asc /opt/pega/prometheus/jmx_prometheus_javaagent.jar && \
rm /tmp/jmx_prometheus_javaagent-0.18.0.jar.asc && \
# Updating Bouncy Castle jars versions below?  As these are used for FIPS 140-3 support, the versions below should
# only be replaced with FIPS certified library versions.  See https://www.bouncycastle.org/download/bouncy-castle-java-fips/#latest --
# paying particular attention to the "Distribution Files (JAR Format)".  The jars below correspond to BC-FJA 2.0.0.
curl -sL -o /opt/pega/bcfips/bc-fips-2.0.0.jar https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/2.0.0/bc-fips-2.0.0.jar && \
curl -sL -o /tmp/bc-fips-2.0.0.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/2.0.0/bc-fips-2.0.0.jar.asc && \
curl -sL -o /opt/pega/bcfips/bctls-fips-2.0.19.jar https://repo1.maven.org/maven2/org/bouncycastle/bctls-fips/2.0.19/bctls-fips-2.0.19.jar && \
curl -sL -o /tmp/bctls-fips-2.0.19.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bctls-fips/2.0.19/bctls-fips-2.0.19.jar.asc && \
curl -sL -o /opt/pega/bcfips/bcpkix-fips-2.0.7.jar https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/2.0.7/bcpkix-fips-2.0.7.jar && \
curl -sL -o /tmp/bcpkix-fips-2.0.7.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/2.0.7/bcpkix-fips-2.0.7.jar.asc && \
curl -sL -o /opt/pega/bcfips/bcutil-fips-2.0.3.jar https://repo1.maven.org/maven2/org/bouncycastle/bcutil-fips/2.0.3/bcutil-fips-2.0.3.jar && \
curl -sL -o /tmp/bcutil-fips-2.0.3.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcutil-fips/2.0.3/bcutil-fips-2.0.3.jar.asc && \
curl -sL -o /opt/pega/bcfips/bcmail-fips-2.0.5.jar https://repo1.maven.org/maven2/org/bouncycastle/bcmail-fips/2.0.5/bcmail-fips-2.0.5.jar && \
curl -sL -o /tmp/bcmail-fips-2.0.5.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcmail-fips/2.0.5/bcmail-fips-2.0.5.jar.asc && \
curl -sL -o /opt/pega/bcfips/bcjmail-fips-2.0.5.jar https://repo1.maven.org/maven2/org/bouncycastle/bcjmail-fips/2.0.5/bcjmail-fips-2.0.5.jar && \
curl -sL -o /tmp/bcjmail-fips-2.0.5.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcjmail-fips/2.0.5/bcjmail-fips-2.0.5.jar.asc && \
curl -sL -o /opt/pega/bcfips/bcpg-fips-2.0.9.jar https://repo1.maven.org/maven2/org/bouncycastle/bcpg-fips/2.0.9/bcpg-fips-2.0.9.jar && \
curl -sL -o /tmp/bcpg-fips-2.0.9.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcpg-fips/2.0.9/bcpg-fips-2.0.9.jar.asc && \
gpg --import /keys/bc_maven_public_key.asc && \
gpg --verify /tmp/bc-fips-2.0.0.jar.asc /opt/pega/bcfips/bc-fips-2.0.0.jar && \
rm /tmp/bc-fips-2.0.0.jar.asc && \
gpg --verify /tmp/bctls-fips-2.0.19.jar.asc /opt/pega/bcfips/bctls-fips-2.0.19.jar && \
rm /tmp/bctls-fips-2.0.19.jar.asc && \
gpg --verify /tmp/bcpkix-fips-2.0.7.jar.asc /opt/pega/bcfips/bcpkix-fips-2.0.7.jar && \
rm /tmp/bcpkix-fips-2.0.7.jar.asc && \
gpg --verify /tmp/bcutil-fips-2.0.3.jar.asc /opt/pega/bcfips/bcutil-fips-2.0.3.jar && \
rm /tmp/bcutil-fips-2.0.3.jar.asc && \
gpg --verify /tmp/bcmail-fips-2.0.5.jar.asc /opt/pega/bcfips/bcmail-fips-2.0.5.jar && \
rm /tmp/bcmail-fips-2.0.5.jar.asc && \
gpg --verify /tmp/bcjmail-fips-2.0.5.jar.asc /opt/pega/bcfips/bcjmail-fips-2.0.5.jar && \
rm /tmp/bcjmail-fips-2.0.5.jar.asc && \
gpg --verify /tmp/bcpg-fips-2.0.9.jar.asc /opt/pega/bcfips/bcpg-fips-2.0.9.jar && \
rm /tmp/bcpg-fips-2.0.9.jar.asc && \
chgrp -R 0 /opt/pega/prometheus && \
chmod -R g+rw /opt/pega/prometheus && \
chown -R pegauser /opt/pega/prometheus && \
chmod 440 /opt/pega/prometheus/jmx_prometheus_javaagent.jar 
```
1. Please note yum update will contact enabled repositories to fetch the packages and their latest versions.The repositories are defined in the /etc/yum.repos.d directory.
2. If building an image using RHEL, yum update will try to contact Red Hat repos and therefore you will need to confirm your identity using subscription-manager in the Dockerfile to connect to the Red Hat 
   repositories.
