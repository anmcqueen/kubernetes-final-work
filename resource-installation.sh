# TODO прописать верные пути к файлам
# Предварительно установлен helm "v3.11.2"

# Создан alias
alias kl=kubectl

cd kubernetes-final-work

# Установка YandexCloud CLI
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init
# Подключение к кластеру sock-shop-cluster
yc managed-kubernetes cluster \
  get-credentials sock-shop-neo \
  --external

# Установка ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx --create-namespace

# Установка Cert-manager
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.0 \
  --set installCRDs=true
kl apply -f cert-manager/ClusterIssuer-letsencrypt.yaml


# Установка Sock Shop
kl create ns sock-shop
kl apply -f sock-shop/sock-shop-certificates.yaml
helm upgrade --install --create-namespace sock-shop -n sock-shop helm-charts/sock-shop


# Monitoring & Logging
# Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install --create-namespace --values monitoring/prometheus-values.yaml prometheus -n monitoring prometheus-community/prometheus
##kl apply -f monitoring/prometheus-ingress-no-tls.yaml
# Loki & Promtail
helm upgrade --install --create-namespace --values monitoring/loki-values.yaml loki -n monitoring grafana/loki
kl apply -f monitoring/loki-ingress-no-tls.yaml
helm upgrade --install --create-namespace --values monitoring/promtail-values.yaml promtail -n monitoring grafana/promtail
# Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install --create-namespace --values monitoring/grafana-values.yaml grafana -n monitoring grafana/grafana
kl apply -f monitoring/grafana-certificates.yaml
kl apply -f monitoring/grafana-ingress.yaml
# Получим логин-пароль из секрета grafana
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Затем заходим в grafana https://grafana.anynamefits.ru
# Настраиваем DataSource Prometheus: prometheus-server:80
# Настраиваем DataSource Loki: loki.anynamefits.ru
# Настраиваем Dashboards


# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kl apply -f argoCD/argoCD-ingress.yaml
argocd admin initial-password -n argocd
# В интерфейсе применить argoCD/argoCD-application-helm.yaml