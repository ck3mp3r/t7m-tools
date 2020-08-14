#!/usr/bin/env bash

(return 0 2>/dev/null) && sourced=1 || sourced=0

if [ $sourced == 0 ]; then
  echo "Usage: 'source aws-profile [profile]'"
  exit 1
fi

if [ -z "$1" ]; then
  PROFILES=`aws configure list-profiles`
  PROFILES=($PROFILES)
  for index in "${!PROFILES[@]}"; do echo "$index - ${PROFILES[$index]}"; done
  read -p "Please pick a profile: " index
  PROFILE=${PROFILES[$index]}
else
  PROFILE=$1
fi

echo "Activating AWS_PROFILE: $PROFILE"
export AWS_PROFILE=$PROFILE
