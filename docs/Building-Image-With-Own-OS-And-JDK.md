# Instructions to build custom pega-ready image on OS and JDK of preferred choice.

Prerequisite:- Basic knowledge of Docker and Linux commands.


### Steps to build pega-ready image.

  1. Navigate to https://github.com/pegasystems/docker-pega-web-ready . This is the open source code repository for pega-ready image.
  2. We highly recommend that user should get familiarised with basic docker commands used here. https://github.com/pegasystems/docker-pega-web-ready/blob/master/Dockerfile
  3. We will need `detemplatize` exe to be available under the `bin` directory of the base OS. Use Multistage docker build to copy the executable.
     This detemplatize exe can be located inside the bin folder of this image https://hub.docker.com/r/pegasystems/detemplatize. Please see the reference below and make changes in Dockerfile.
     ```Dockerfile
      FROM pegasystems/detemplatize AS builder
      # Base Image to be used to build pega-ready image 
      FROM <BASE_IMAGE>
      # Copy detemplatize to base image bin directory
      COPY --from=builder /bin/detemplatize /bin/detemplatize
     ```
       
  4. We take base image as an argument to build the pega-ready image. Once you have finalised the base image to be used , we can pass the same base image in the docker run command.
      ```bash
         docker build --build-arg BASE_TOMCAT_IMAGE=<BASE_IMAGE> -t <IMAGE_NAME> .
      ```
     
  5. On successful execution of the above command , we have build the pega-ready image.

###  Note
  1. Please make sure that base image selected should have $CATALINA_HOME set to correct tomcat location.
  2. You can add any extra environment variables needed in the Dockerfile as per your use-case.

