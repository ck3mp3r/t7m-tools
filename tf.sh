#!/usr/bin/env bash

color="-no-color"

while [[ "$#" -gt 0 ]]; do case $1 in
  -e|--env) env="$2"; shift;;
  -i|--init) init=1;;
  -c|--color) color="";;
  plan) action="plan -detailed-exitcode";;
  *) action=$1;;
esac; shift; done

if [[ $init == 1 ]]; then
  rm -fr .terraform
  terraform init $color -backend-config var/$env.hcl
fi
terraform $action $color -var-file var/$env.tfvars
