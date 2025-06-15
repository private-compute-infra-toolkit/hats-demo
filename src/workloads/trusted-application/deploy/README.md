In the run folder, run:

# Kubernetes Kind

Create kind cluster:

```
kind create cluster --config kubernetes-kind.yaml
```

Load tvs:latest and launcher:latest to the kubernetes cluster:

kind load docker-image tvs:latest
kind load docker-image launcher:latest

To view and debug the worload

kind logs -f <e.g. server1-deployment-84cfff678b-z6kk6>
