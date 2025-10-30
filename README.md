#### How to access kubernetes dashboard
`minikube dashboard --url`
`kubectl proxy --port=8001 --address='192.168.32.128' --accept-hosts='^.*'`

#### How to make minikube node behind a proxy
1. create a file `proxy.sh` in the directory `~/.minikube/files/etc/profile.d`, creating the directory if necessary
    `vim ~/.minikube/files/etc/profile.d/proxy.sh`
2. Fill the file content like below:
    ```shell
    export HTTP_PROXY=http://flying.host:7890
    export HTTPS_PROXY=http://flying.host:7890
    export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.49.0/24,192.168.39.0/24
    ```
3. Assign execute permission to the file
    `chmod +x ~/.minikube/files/etc/profile.d/proxy.sh`
4. restart the minikube

#### How to add a host mapping to hosts file in minikube node
1. create a file `rc.local` in the directory `~/.minikube/files/etc`, creating the directory if necessary
   `vim ~/.minikube/files/etc/rc.local`
2. Fill the file content like below:
    ```shell
    #!/bin/bash
    sudo echo "192.168.31.182 flying.host" >> /etc/hosts
    exit 0
    ```
3. Assign execute permission to the file
   `chmod +x ~/.minikube/files/etc/rc.local`
4. restart the minikube(Maybe you need to restart minikube twice or more to make it work)

#### How to clean minikube cache to prevent from insufficiency disk space
1. locate directory `~/.minikube/cache`
2. delete some cache data according to your own situation such as images `rm -rf ~/.minikube/cache/images/amd64/*`

