# All lendingblock images
AWS_ACCOUNT_ID ?= 218064433954
AWS_DEFAULT_REGION ?= eu-west-2
NS = ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
REPO := loan-contracts

ifdef CODEBUILD_GIT_BRANCH
BRANCH := $(CODEBUILD_GIT_BRANCH)
REF_NAME := $(CODEBUILD_GIT_COMMIT_SHORT)
else
BRANCH := $(shell git symbolic-ref --short -q HEAD)
REF_NAME := $(shell git rev-parse HEAD | egrep -o '[a-z0-9]{8}' | head -n 1 )
endif

VERSION ?= ${BRANCH}-${REF_NAME}
DOCKER_IMAGE ?= ${NS}/${REPO}:${VERSION}

.PHONY: help test 

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

image:		## Build the docker image
	docker build -t $(DOCKER_IMAGE) .

push:		## Push docker image to Amazon ECR
	docker push $(DOCKER_IMAGE)

shell:		## Push docker image to Amazon ECR
	docker run --rm -it $(DOCKER_IMAGE) /bin/sh

test:
	docker run --rm $(DOCKER_IMAGE) npm run test
