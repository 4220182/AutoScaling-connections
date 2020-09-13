#!/usr/bin/env bash

cat $BINDING_CONTEXT_PATH >/tmp/tmp.log

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- name: OnModifiedTest
  apiVersion: extensions/v1beta1
  kind: Deployment
  nameSelector:
    matchNames:
    - nginx
  labelSelector:
    matchLabels:
      app: nginx
  namespace:
    nameSelector:
      matchNames:
        - default
  executeHookOnEvent:
  - Modified
  jqFilter: ".spec.replicas"
EOF
else
    bindingName=`jq -r ".[0].binding" $BINDING_CONTEXT_PATH`
    resourceEvent=`jq -r ".[0].watchEvent" $BINDING_CONTEXT_PATH`
    resourceName=`jq -r ".[0].object.metadata.name" $BINDING_CONTEXT_PATH`
    resourceReplicas=`jq -r ".[0].object.spec.replicas" $BINDING_CONTEXT_PATH`

    if [[ $resourceReplicas != "null" ]] ; then
      echo "deployment $resourceName replicas is: $resourceReplicas"

    fi
fi