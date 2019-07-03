#!/bin/bash

set -e



echo $1
echo $2

curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

container-structure-test test --image $1/$2:testimage --config tests/pega-web-ready-testcases.yaml
