#### How to install
`kubectl create ns kelcin-nfs-server`
`helm install -n kelcin-nfs-server nfs-server ./nfs-server-1.0.0.tgz --debug --dry-run`
`helm install -n kelcin-nfs-server nfs-server ./nfs-server-1.0.0.tgz`

#### How to uninstall
`helm uninstall -n kelcin-nfs-server nfs-server`