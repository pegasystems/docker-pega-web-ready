# Build a custom pega-web-ready Docker image using your preferred OS and JDK

Prerequisites:
• You have a basic knowledge of Docker and Linux commands.
• You have a base Docker image with your preferred OS and JDK.
• The base image you selected must have $CATALINA_HOME set to the correct tomcat location.

Pega provides a pega-web-ready Docker image using Tomcat 9 and JDK 11 as a base image. For more information about the pega-web-ready Docker image, see `pegasystems/docker-pega-web-ready`
To build a custom pega-web-ready image using your preferred OS and JDK, perform the following actions:

1. Create a Dockerfile for your custom pega-web-ready image using your base image.
     
   a. Use multi-stage Docker build at the beginning of your Dockerfile to copy the detemplatize executive file from the `pegasystems/detemplatize` Docker image to your base image.
      The detemplatize executive file replaces template variables with actual values in the Pega Platform code.

   For example:
      ```Dockerfile
      FROM pegasystems/detemplatize AS builder
      # Base Image to be used to build pega-ready image 
      FROM <BASE_IMAGE>
      # Copy detemplatize to base image bin directory
      COPY --from=builder /bin/detemplatize /bin/detemplatize 
      ```
   
   b. Use the open-source pega-web-ready Dockerfile code to complete the Dockerfile.
      For more information, see pegasystems/docker-pega-web-ready/Dockerfile.
      Note: You can add any extra environment variables needed in the Dockerfile as per your use-case.


2. Use the following command to build the custom pega-web-ready image using the base image as an argument.
     ```bash
        docker build --build-arg BASE_TOMCAT_IMAGE=<BASE_IMAGE> -t <IMAGE_NAME> .
     ```
     
The system then builds your custom pega-web-ready Docker image.
