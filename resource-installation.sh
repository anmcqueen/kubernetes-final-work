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
  get-credentials sock-shop-cluster \
  --external

# Установка ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx --create-namespace
# После этого можно пересоздать LoadBalancer с указанием зарезервированного статического IP-адреса,
# kl apply -f ingress-nginx/LoadBalancer-ingress.yaml
# либо в Облачном провайдере (YandexCloud) сделать статическим тот IP-адрес, который случайным образом выберет LoadBalancer при создании.
# Необходимо добавить этот IP-адрес в ресурсные записи A@ u A* домена.

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
##kl apply -f monitoring/vault-ingress.yaml
# Loki & Promtail
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install --create-namespace --values monitoring/loki-values.yaml loki -n monitoring grafana/loki
kl apply -f monitoring/loki-ingress-no-tls.yaml
helm upgrade --install --create-namespace --values monitoring/promtail-values.yaml promtail -n monitoring grafana/promtail
# Grafana
#helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install --create-namespace --values monitoring/grafana-values.yaml grafana -n monitoring grafana/grafana
kl apply -f monitoring/grafana-certificates.yaml
kl apply -f monitoring/grafana-ingress.yaml
# Получим логин-пароль из секрета grafana
kl get secret -n monitoring grafana -o json

# Затем заходим в grafana https://grafana.anynamefits.ru
# Настраиваем DataSource Prometheus: prometheus-server:80
# Настраиваем DataSource Loki: loki.anynamefits.ru
# Настраиваем Dashboards
# При проблемах с отображением дашборда с логами помогает перезагрузить поды promtail.


# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kl apply -f argoCD/argoCD-ingress.yaml
argocd admin initial-password -n argocd
# argocd account update-password
# В интерфейсе применить argoCD/argoCD-application-helm.yaml

# Hashicorp Vault
# Создайте сервисный аккаунт
yc iam service-account create --name vault-kms
# Создайте авторизованный ключ для сервисного аккаунта и сохраните его в файл authorized-key.json
yc iam key create \
  --service-account-name vault-kms \
  --output authorized-key.json
# Создайте симметричный ключ Key Management Service
yc kms symmetric-key create \
  --name example-key \
  --default-algorithm aes-256 \
  --rotation-period 24h
  #id: abjctdo9sl0mp1fckuqn
yc resource-manager folder add-access-binding \
  --id b1g2kpq6b36nuse9tnl1 \
  --service-account-name vault-kms \
  --role kms.keys.encrypterDecrypter
# Установка Vault с помощью Helm-чарта
export HELM_EXPERIMENTAL_OCI=1 && \
cat authorized-key.json | helm registry login cr.yandex --username 'json_key' --password-stdin && \
helm pull oci://cr.yandex/yc-marketplace/yandex-cloud/vault/chart/vault \
  --version 0.22.0-1 \
  --untar && \
helm install \
  --namespace vault \
  --create-namespace \
  --set-file yandexKmsAuthJson=authorized-key.json \
  hashicorp ./vault/
# Выполните инициализацию хранилища
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault operator init
# Ingress для Vault
kl apply -f vault/vault-ingress.yaml

# Залогинимся в vault
kubectl exec -it vault-0 -n vault -- vault login
# Включаем хранилище секретов с путем secrets и добавляем секреты
kubectl exec -it vault-0 -n vault -- vault secrets enable --path=secrets kv
kubectl exec -it vault-0 -n vault -- vault kv put secrets/sock-shop/mysql-access username='socksdb' password='***' # пароль замаскирован

# Настройка аутентификации  в Kubernetes
kubectl exec -it vault-0 -n vault -- vault auth enable kubernetes
# Настраиваем доступ к API Kubernetes
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes control' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/config kubernetes_host="K8S_HOST:443"
# Создаем политику
kubectl exec -it vault-0 -n vault -- vault policy write service - <<EOF
path "secrets/*" {
  capabilities = ["read", "list"]
}
EOF
# Создаем роль
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/role/service \
  bound_service_account_names=* \
  bound_service_account_namespaces=* \
  policies=service \
  ttl=24h

#kubectl exec -it vault-0 -n vault -- vault read otus/otus-ro/config
#kubectl exec -it vault-0 -n vault -- vault kv get secrets/sock-shop/mysql-access










