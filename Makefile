TAG = "2.0.0"
PREFIX = "arvasrikanth"
REPO_NAME = "docker-pega-web-ready"

all: image

container: image

image:
	docker build -t $(PREFIX)/$(REPO_NAME) . --target testimage # Build new image and automatically tag it as latest
	docker tag $(PREFIX)/$(REPO_NAME) $(PREFIX)/$(REPO_NAME):$(TAG)  # Add the version tag to the latest image

push: image
	docker push $(PREFIX)/$(REPO_NAME) 
