#### How to install
`kubectl create ns kelcin`
`helm install -n kelcin mysql ./mysql-1.0.0.tgz --debug --dry-run`
`helm install -n kelcin mysql ./mysql-1.0.0.tgz`

#### How to uninstall
`helm uninstall -n kelcin mysql`

### How to expose service port to host machine for being accessed by other mysql client
`kubectl port-forward --address 0.0.0.0 service/mysql-svc 3306:3306`