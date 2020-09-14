#!/usr/bin/env bash

cat $BINDING_CONTEXT_PATH >/tmp/tmp.log

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- name: OnModifiedTest
  apiVersion: apps/v1
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
      echo "$resourceName replicas is: $resourceReplicas; ambassador replicas is: $AMBASSADOR_NUMBERS"
      export MAX_CONNECTIONS=`expr $resourceReplicas \* $APP_BASE_CONNECTIONS / $AMBASSADOR_NUMBERS / 2`
      export MAX_PENDING_REQUESTS=`expr $resourceReplicas \* $APP_BASE_CONNECTIONS / $AMBASSADOR_NUMBERS / 2`
      cat /templates/module-template.yaml |envsubst |kubectl apply -f -
      echo "ambassador MAX_CONNECTIONS is: $MAX_CONNECTIONS ; MAX_PENDING_REQUESTS is: $MAX_PENDING_REQUESTS"
    fi
fi