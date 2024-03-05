IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),pega-ready)

all: image

container: image

image:
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=tomcat:9-jdk17 -t $(IMAGE_NAME) . # Build image and automatically tag it as latest
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=tomcat:9-jdk11 -t $(IMAGE_NAME):3-jdk11 . # Build image using tomcat 9 , jdk 11
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=tomcat:9-jdk17 -t $(IMAGE_NAME):3-jdk17 . # Build image using tomcat 9 , jdk 17

test: image
	# Build image for executing test cases against it
	docker build --build-arg VERSION=$(VERSION) --build-arg BASE_TOMCAT_IMAGE=tomcat:9-jdk11 -t qualitytest . --target qualitytest
	# Execute test cases
	container-structure-test test --image qualitytest --config tests/pega-web-ready-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases_jdk17_version.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk11 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk11 --config tests/pega-web-ready-release-testcases_jdk11_version.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk17 --config tests/pega-web-ready-release-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME):3-jdk17 --config tests/pega-web-ready-release-testcases_jdk17_version.yaml

push: image
	docker push $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):3-jdk11
	docker push $(IMAGE_NAME):3-jdk17