IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),pega-ready)
MAJOR_MINOR := $(if $(MAJOR_MINOR),$(MAJOR_MINOR),CUSTOM)
BUILD_NUMBER := $(if $(GITHUB_RUN_NUMBER),$(GITHUB_RUN_NUMBER),BUILD)
VERSION := $(if $(VERSION),$(VERSION),$(MAJOR_MINOR).$(BUILD_NUMBER))
DETEMPLATIZE_IMAGE_VERSION:= $(if $(DETEMPLATIZE_IMAGE_VERSION),$(DETEMPLATIZE_IMAGE_VERSION),latest)

all: image

container: image

image:
	(cd versionchecker && ./gradlew build)
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=saurabhkumar2029/pega:fedora --build-arg DETEMPLATIZE_IMAGE_VERSION=$(DETEMPLATIZE_IMAGE_VERSION) -t $(IMAGE_NAME) . # Build image and automatically tag it as latest on jdk17

