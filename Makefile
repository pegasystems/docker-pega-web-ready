#REPO_PREFIX = $(shell git config --get remote.origin.url | tr ':.' '/'  | rev | cut -d '/' -f 3 | rev)
#REPO = $(REPO_PREFIX)/pega-ready
IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),"pega-ready")

all: image

container: image

image:
	docker build -t $(IMAGE_NAME) . # Build image and automatically tag it as latest

test: image
	# Build image for executing test cases against it
	docker build -t qualitytest . --target qualitytest
	# Execute test cases
	container-structure-test test --image qualitytest --config tests/pega-web-ready-testcases.yaml
	container-structure-test test --image $(IMAGE_NAME) --config tests/pega-web-ready-release-testcases.yaml

push: image
	docker push $(IMAGE_NAME):latest
