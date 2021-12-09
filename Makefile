IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),pega-ready)
MAJOR_MINOR := $(if $(MAJOR_MINOR),$(MAJOR_MINOR),CUSTOM)
BUILD_NUMBER := $(if $(GITHUB_RUN_NUMBER),$(GITHUB_RUN_NUMBER),BUILD)
VERSION := $(if $(VERSION),$(VERSION),$(MAJOR_MINOR).$(BUILD_NUMBER))

all: image

container: image

image:
	docker build --build-arg VERSION=$(VERSION) -t $(IMAGE_NAME) . # Build image and automatically tag it as latest

test: image
	# Build image for executing test cases against it
	docker build --build-arg VERSION=$(VERSION) -t qualitytest . --target qualitytest
	# Execute test cases
	container-structure-test test --image qualitytest --config tests/pega-web-ready-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases.yaml

push: image
	docker tag $(IMAGE_NAME):latest $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest
