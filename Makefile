TAG = "2.0.0"
PREFIX = $(shell git config --get remote.origin.url | tr ':.' '/'  | rev | cut -d '/' -f 3 | rev)
REPO_NAME = "pega-ready"

all: image

container: image

image:
	docker build -t $(PREFIX)/$(REPO_NAME) . # Build new image and automatically tag it as latest
	docker tag $(PREFIX)/$(REPO_NAME) $(PREFIX)/$(REPO_NAME):$(TAG)  # Add the version tag to the latest image

push: image
	docker push $(PREFIX)/$(REPO_NAME) 
