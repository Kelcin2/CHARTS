#### How to install
`kubectl create ns kelcin`
`helm install -n kelcin ray-serve ./ray-serve-1.0.0.tgz --debug --dry-run`
`helm install -n kelcin ray-serve ./ray-serve-1.0.0.tgz`

#### How to uninstall
`helm uninstall -n kelcin ray-serve`

### How to expose service port to host machine for being accessed by postman or other REST Client
`kubectl port-forward --address 0.0.0.0 service/ray-serve-svc 8000:80`

### How to expose dashboard port to host machine for being accessed by postman or other REST Client
`kubectl port-forward --address 0.0.0.0 service/ray-serve-svc 8265:8265`