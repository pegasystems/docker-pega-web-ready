# To change the base images used for the build, create a file similar to the included config.mk file
# and invoke the the build like follows:
#
#    make -e BUILD_CONFIG=alt_config.mk test
#

BUILD_CONFIG = config.mk
include ${BUILD_CONFIG}

IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),pega-ready)
MAJOR_MINOR := $(if $(MAJOR_MINOR),$(MAJOR_MINOR),CUSTOM)
BUILD_NUMBER := $(if $(GITHUB_RUN_NUMBER),$(GITHUB_RUN_NUMBER),BUILD)
VERSION := $(if $(VERSION),$(VERSION),$(MAJOR_MINOR).$(BUILD_NUMBER))
DETEMPLATIZE_IMAGE_VERSION:= $(if $(DETEMPLATIZE_IMAGE_VERSION),$(DETEMPLATIZE_IMAGE_VERSION),latest)

JDK11_CRP := "$(shell docker run --entrypoint /bin/bash ${JDK11_BASE_IMG} -c "realpath \$$CATALINA_HOME | tr -d '[:cntrl:]'")"
JDK11_CCRP := $(shell docker run --entrypoint /bin/bash ${JDK11_BASE_IMG} -c "realpath \$$JAVA_HOME/lib/security/cacerts | tr -d '[:cntrl:]'")
JDK17_CRP := $(shell docker run --entrypoint /bin/bash ${JDK17_BASE_IMG} -c "realpath \$$CATALINA_HOME | tr -d '[:cntrl:]'")
JDK17_CCRP := $(shell docker run --entrypoint /bin/bash ${JDK17_BASE_IMG} -c "realpath \$$JAVA_HOME/lib/security/cacerts | tr -d '[:cntrl:]'")
JDK21_CRP := "$(shell docker run --entrypoint /bin/bash ${JDK21_BASE_IMG} -c "realpath \$$CATALINA_HOME | tr -d '[:cntrl:]'")"
JDK21_CCRP := $(shell docker run --entrypoint /bin/bash ${JDK21_BASE_IMG} -c "realpath \$$JAVA_HOME/lib/security/cacerts | tr -d '[:cntrl:]'")
CATALINA_PATH_SUBSTITUTION := $(shell echo ${JDK11_CRP} | sed 's/\//\\\//g')

all: image

container: image

image:
	(cd versionchecker && ./gradlew build)
	docker build --build-arg VERSION=$(VERSION) --build-arg CATALINA_REAL_PATH=$(JDK17_CRP) --build-arg CACERTS_REAL_PATH=$(JDK17_CCRP) --build-arg BASE_TOMCAT_IMAGE=${JDK17_BASE_IMG} --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) --build-arg TOMCAT_MAJOR_VERSION=9 -t $(IMAGE_NAME) . # Build image and automatically tag it as latest on jdk17
	docker build --build-arg VERSION=$(VERSION) --build-arg CATALINA_REAL_PATH=${JDK11_CRP} --build-arg CACERTS_REAL_PATH=${JDK11_CCRP} --build-arg BASE_TOMCAT_IMAGE=${JDK11_BASE_IMG} --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) --build-arg TOMCAT_MAJOR_VERSION=9 -t $(IMAGE_NAME)\:4-jdk11 . # Build image using tomcat 9 , jdk 11
	docker build --build-arg VERSION=$(VERSION) --build-arg CATALINA_REAL_PATH=${JDK17_CRP} --build-arg CACERTS_REAL_PATH=${JDK17_CCRP} --build-arg BASE_TOMCAT_IMAGE=${JDK17_BASE_IMG} --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) --build-arg TOMCAT_MAJOR_VERSION=9 -t $(IMAGE_NAME)\:4-jdk17 . # Build image using tomcat 9 , jdk 17
	docker build --build-arg VERSION=$(VERSION) --build-arg CATALINA_REAL_PATH=${JDK21_CRP} --build-arg CACERTS_REAL_PATH=${JDK21_CCRP} --build-arg BASE_TOMCAT_IMAGE=${JDK21_BASE_IMG} --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) --build-arg TOMCAT_MAJOR_VERSION=10 -t $(IMAGE_NAME)\:4-jdk21 . # Build image using tomcat 10 , jdk 21

test: image
	# Build image for executing test cases against it
	docker build --build-arg VERSION=$(VERSION) --build-arg CATALINA_REAL_PATH=${JDK11_CRP} --build-arg CACERTS_REAL_PATH=${JDK11_CCRP} --build-arg BASE_TOMCAT_IMAGE=${JDK11_BASE_IMG} -t qualitytest . --target qualitytest
	# Setup test assets
	$(shell sed 's/@@CATALINA_PATH@@/${CATALINA_PATH_SUBSTITUTION}/' tests/test-artifacts/expected_prweb.xml > tests/test-artifacts/expected_prweb_temp.xml)
	$(shell sed 's/@@CATALINA_PATH@@/${CATALINA_PATH_SUBSTITUTION}/' tests/test-artifacts/expected_prweb_hz_ssl.xml > tests/test-artifacts/expected_prweb_hz_ssl_temp.xml)
	$(shell sed 's/@@CATALINA_PATH@@/${CATALINA_PATH_SUBSTITUTION}/' tests/test-artifacts/expected_prweb_withDefaultStreamProvider.xml > tests/test-artifacts/expected_prweb_withDefaultStreamProvider_temp.xml)
	# Execute test cases
	container-structure-test test --image qualitytest --config tests/pega-web-ready-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases_jdk17_version.yaml
	container-structure-test test --image $(IMAGE_NAME):4-jdk11 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):4-jdk11 --config tests/pega-web-ready-release-testcases_jdk11_version.yaml
	container-structure-test test --image $(IMAGE_NAME):4-jdk17 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):4-jdk17 --config tests/pega-web-ready-release-testcases_jdk17_version.yaml
	container-structure-test test --image $(IMAGE_NAME):4-jdk21 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):4-jdk21 --config tests/pega-web-ready-release-testcases_jdk21_version.yaml

push: image
	docker tag $(IMAGE_NAME):4-jdk11 $(IMAGE_NAME):$(VERSION)-jdk11
	docker tag $(IMAGE_NAME):4-jdk17 $(IMAGE_NAME):$(VERSION)-jdk17
	docker tag $(IMAGE_NAME):4-jdk21 $(IMAGE_NAME):$(VERSION)-jdk21
	docker push $(IMAGE_NAME):$(VERSION)-jdk11
	docker push $(IMAGE_NAME):$(VERSION)-jdk17
	docker push $(IMAGE_NAME):$(VERSION)-jdk21
	docker push $(IMAGE_NAME):4-jdk11
	docker push $(IMAGE_NAME):4-jdk17
	docker push $(IMAGE_NAME):4-jdk21
	docker push $(IMAGE_NAME):latest