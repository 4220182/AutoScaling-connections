#!/usr/bin/env bash

cat $BINDING_CONTEXT_PATH >/tmp/tmp.log

changeConns(){
      AMBASSADOR_NUMBERS=$1
      APP_NUMBERS=$2
      APP_BASE_CONNECTIONS=$3
      export MAX_CONNECTIONS=`expr $APP_NUMBERS \* $APP_BASE_CONNECTIONS / $AMBASSADOR_NUMBERS / 2`
      export MAX_PENDING_REQUESTS=`expr $APP_NUMBERS \* $APP_BASE_CONNECTIONS / $AMBASSADOR_NUMBERS / 2`
      cat /templates/module-template.yaml |envsubst |kubectl apply -f -
}

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
    - ambassador
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

    if [[ $resourceName == "nginx" ]] && [[ $resourceReplicas != "null" ]] ; then

      AMBASSADOR_NUMBERS=`kubectl get deployment ambassador -o json |jq -r ".spec.replicas"`
      changeConns $AMBASSADOR_NUMBERS $resourceReplicas $APP_BASE_CONNECTIONS
      echo "$resourceName replicas is: $resourceReplicas; ambassador replicas is: $AMBASSADOR_NUMBERS"
      echo "ambassador MAX_CONNECTIONS is: $MAX_CONNECTIONS ; MAX_PENDING_REQUESTS is: $MAX_PENDING_REQUESTS"
      echo "{\"name\":\"TEST_MAX_CONNECTIONS\",\"set\":$MAX_CONNECTIONS,\"labels\":{\"source\":\"source1\"}}" >> $METRICS_PATH

    elif [[ $resourceName == "ambassador" ]] && [[ $resourceReplicas != "null" ]] ; then

      NGINX_NUMBERS=`kubectl get deployment nginx -o json |jq -r ".spec.replicas"`
      changeConns $resourceReplicas $NGINX_NUMBERS $APP_BASE_CONNECTIONS
      echo "$resourceName replicas is: $resourceReplicas; nginx replicas is: $resourceReplicas"
      echo "ambassador MAX_CONNECTIONS is: $MAX_CONNECTIONS ; MAX_PENDING_REQUESTS is: $MAX_PENDING_REQUESTS"

    fi
fi