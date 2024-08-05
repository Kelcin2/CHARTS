#### How to install
`kubectl create ns kelcin`
`helm install -n kelcin vllm-cpu ./vllm-cpu-1.0.0.tgz --debug --dry-run`
`helm install -n kelcin vllm-cpu ./vllm-cpu-1.0.0.tgz`

#### How to uninstall
`helm uninstall -n kelcin vllm-cpu`

### How to expose service port to host machine for being accessed by postman or other REST Client
`kubectl port-forward --address 0.0.0.0 service/vllm-cpu-svc 8000:80`