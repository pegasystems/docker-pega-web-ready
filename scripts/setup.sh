#!/bin/bash

set -e


git config --get remote.origin.url | tr ':.' '/'  | rev | cut -d '/' -f 3 | rev

git config --get remote.origin.url

git remote show origin

curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

container-structure-test test --image pegasystems/pega-ready --config scripts/testcases.yaml
