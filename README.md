# AutoScaling-connections

```shell
# cat scp.sh 
#!/bin/bash

scp -r test@192.168.5.102:~/PycharmProjects/AutoScaling-connections .
cd AutoScaling-connections
docker build -t koza/autoscaling-conn:latest .
```