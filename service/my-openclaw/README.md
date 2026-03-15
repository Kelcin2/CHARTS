#### How to install
`kubectl create ns kelcin`
`helm install -n kelcin my-openclaw ./my-openclaw-1.0.0.tgz --set deployment.openclaw.model.config.apiKey=YOUR_API_KEY --debug --dry-run=client`
`helm install -n kelcin my-openclaw ./my-openclaw-1.0.0.tgz --set deployment.openclaw.model.config.apiKey=YOUR_API_KEY`

#### How to uninstall
`helm uninstall -n kelcin my-openclaw`

### How to expose service port to host machine for being accessed by Browser
`kubectl port-forward --address 0.0.0.0 service/openclaw-svc 18789:80`