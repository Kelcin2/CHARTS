#### How to install
`kubectl create ns kelcin`
`helm install -n kelcin volume-config ./volume-config-1.0.0.tgz --debug --dry-run=server`
`helm install -n kelcin volume-config ./volume-config-1.0.0.tgz`

#### How to uninstall
`helm uninstall -n kelcin volume-config`