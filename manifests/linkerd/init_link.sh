# Iniciar a visualização de metricas da aplicação
linkerd viz install | kubectl apply -f -
kubectl apply -f ../ingress-nginx/linkerd-ingress.yml

