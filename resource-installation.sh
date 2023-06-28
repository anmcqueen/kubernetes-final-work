# TODO прописать верные пути к файлам
# Предварительно установлен helm "v3.11.2"

# Создан alias
alias kl=kubectl

# Установка YandexCloud CLI
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init
# Подключение к кластеру sock-shop-cluster
yc managed-kubernetes cluster \
  get-credentials sock-shop-cluster \
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


# Установка Sock Shop (будет переделано)
kl create ns sock-shop
kl apply -f sock-shop/sock-shop-certificates.yaml
helm upgrade --install --create-namespace sock-shop -n sock-shop kubernetes-final-work/helm-charts/sock-shop


# Monitoring
# Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install --create-namespace --values monitoring/prometheus-values.yaml prometheus -n monitoring prometheus-community/prometheus

# Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install --create-namespace --values grafana-values.yaml grafana -n monitoring grafana/grafana
# Получила логин-пароль из секрета grafana
kl get secret -n monitoring grafana -o json
kl apply -f monitoring/grafana-certificates.yaml
# Ingress для sock-shop (frontend)
kl apply -f Ingress/grafana-ingress-no-tls.yaml

# Затем заходим в grafana https://grafana.anynamefits.ru
# Настраиваем DataSource Prometheus: prometheus-server:80