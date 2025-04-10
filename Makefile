IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),pega-ready)
MAJOR_MINOR := $(if $(MAJOR_MINOR),$(MAJOR_MINOR),CUSTOM)
BUILD_NUMBER := $(if $(GITHUB_RUN_NUMBER),$(GITHUB_RUN_NUMBER),BUILD)
VERSION := $(if $(VERSION),$(VERSION),$(MAJOR_MINOR).$(BUILD_NUMBER))
DETEMPLATIZE_IMAGE_VERSION:= $(if $(DETEMPLATIZE_IMAGE_VERSION),$(DETEMPLATIZE_IMAGE_VERSION),latest)

all: image

container: image

image:

	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=saurabhkumar2029/pega:centos --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) -t $(IMAGE_NAME) . # Build image and automatically tag it as latest on jdk17
	(cd versionchecker && ./gradlew build)
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:9-jdk17 --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) -t $(IMAGE_NAME) . # Build image and automatically tag it as latest on jdk17
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:9-jdk11 --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) -t $(IMAGE_NAME):3-jdk11 . # Build image using tomcat 9 , jdk 11
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:9-jdk17 --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) -t $(IMAGE_NAME):3-jdk17 . # Build image using tomcat 9 , jdk 17
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:10-jdk21 --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) -t $(IMAGE_NAME):3-jdk21 . # Build image using tomcat 10 , jdk 21

test: image
	# Build image for executing test cases against it
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=pegasystems/tomcat:9-jdk11 -t qualitytest . --target qualitytest
	# Execute test cases
	container-structure-test test --image qualitytest --config tests/pega-web-ready-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases_jdk17_version.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk11 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk11 --config tests/pega-web-ready-release-testcases_jdk11_version.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk17 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk17 --config tests/pega-web-ready-release-testcases_jdk17_version.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk21 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk21 --config tests/pega-web-ready-release-testcases_jdk21_version.yaml

push: image
	docker tag $(IMAGE_NAME):3-jdk11 $(IMAGE_NAME):$(VERSION)-jdk11
	docker tag $(IMAGE_NAME):3-jdk17 $(IMAGE_NAME):$(VERSION)-jdk17
	docker tag $(IMAGE_NAME):3-jdk21 $(IMAGE_NAME):$(VERSION)-jdk21
	docker push $(IMAGE_NAME):$(VERSION)-jdk11
	docker push $(IMAGE_NAME):$(VERSION)-jdk17
	docker push $(IMAGE_NAME):$(VERSION)-jdk21
	docker push $(IMAGE_NAME):3-jdk11
	docker push $(IMAGE_NAME):3-jdk17
	docker push $(IMAGE_NAME):3-jdk21
	docker push $(IMAGE_NAME):latest
