IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),"pega-ready")

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
	docker push $(IMAGE_NAME)
