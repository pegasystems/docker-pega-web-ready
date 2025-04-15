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

2. Use the following command to build the custom pega-web-ready image using the base image as an argument.
     ```bash
        docker build --build-arg BASE_TOMCAT_IMAGE=<BASE_IMAGE> -t <IMAGE_NAME> .
     ```
     
The system then builds your custom pega-web-ready Docker image.


### Special Instructions for Fedora based OS.

If you are building the image using OS such as RHEL/CentOS which are Fedora based, some of the commands used in Dockerfile will not work.
Fedora uses `yum` or `dnf` as package manager and Debian uses `apt-get` as package manager.

Pega shipped images are built on Ubuntu which is debian based.
Hence in the Dockerfile, it is needed to replace the apt-get references with yum or dnf depending upon the base image selected.

In Dockerfile, in the section where we download necessary jars, we are using apt-get and this has to be replaced with yum or dnf. Look for text `# Fetches the packages and latest versions` in the Dockerfile.
Please see below reference how to replace the apt-get commands with yum command. If yum is not supported for your OS, try with dnf. Replace yum with dnf.

```bash
# Fetches the packages and latest versions.
RUN yum -y update && \
yum install gpg

```
Also comment out below line in Dockerfile. This command is not intended for Fedora based OS is it could impact the OS functionality.
```bash
RUN apt-get autoremove --purge -y gpg
```

1. Please note yum or dnf update will contact enabled mirror repositories to fetch the packages and their latest versions.For yum, the repositories can be configured in the /etc/yum.repos.d directory.
   Please ensure these repositories are reachable within the docker host network.
2. If building an image using RHEL, yum/dnf update will try to contact Red Hat repositories and therefore you will need to confirm your Red Hat identity using subscription-manager to connect to
   the Red Hat repositories. Please refer https://access.redhat.com/solutions/253273 for more details.
3. Curl is needed for downloading few jars in the Dockerfile at the build time. It is recommended to download curl lib or any other similar utility if its not part of your base image.
   If using some alternate for curl, please change the reference of curl accordingly. Alternatively, you can also bake in the required jars in the base image.
