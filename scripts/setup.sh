#!/bin/bash

set -e


git config --get remote.origin.url | tr ':.' '/'  | rev | cut -d '/' -f 3 | rev

git config --get remote.origin.url

git remote show origin

echo 'First arg $1'
echo 'Second arg $2'

curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

container-structure-test test --image $1/$2 --config scripts/testcases.yaml
