TAG = "qualitytest"
PREFIX = "pegasystems"
REPO_NAME = "pega-ready"

all: image

container: image

image:
	docker build -t $(PREFIX)/$(REPO_NAME) . --target qualitytest # Build image for executing test cases against it
	docker tag $(PREFIX)/$(REPO_NAME) $(PREFIX)/$(REPO_NAME):$(TAG)  # Add the version tag to the latest image
	docker build -t $(PREFIX)/$(REPO_NAME) . # Build image and automatically tag it as latest

push: image
	docker push $(PREFIX)/$(REPO_NAME) 
