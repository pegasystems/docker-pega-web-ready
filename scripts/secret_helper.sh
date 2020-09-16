#!/bin/bash

resolveSecretPath() {
  defaultSecretPath=$1
  alternateSecretPath=$2
  secretName=$3

  if [[ -e "${alternateSecretPath}/${secretName}" ]]; then
    result="${alternateSecretPath}/${secretName}"
  else
    result="${defaultSecretPath}/${secretName}"
  fi
  echo "$result"
}

