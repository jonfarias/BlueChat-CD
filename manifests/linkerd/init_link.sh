# Iniciar a visualização de metricas da aplicação
linkerd viz install | kubectl apply -f -
sleep 20s
kubectl apply -f ../ingress-nginx/linkerd-ingress.yml
kubectl get -n bluechat-prod deploy -o yaml | linkerd inject - | kubectl apply -f -
kubectl get -n bluechat-dev deploy -o yaml | linkerd inject - | kubectl apply -f -
