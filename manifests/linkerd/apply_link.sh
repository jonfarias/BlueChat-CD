kubectl get -n bluechat-prod deploy -o yaml | linkerd inject - | kubectl apply -f -
kubectl get -n bluechat-dev deploy -o yaml | linkerd inject - | kubectl apply -f -
