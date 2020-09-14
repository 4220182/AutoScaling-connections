FROM flant/shell-operator:v1.0.0-beta.12
ADD hook.sh /hooks
RUN mkdir /templates
ADD module-template.yaml /templates/module-template.yaml
RUN apt-get update && apt-get install -y gettext-base