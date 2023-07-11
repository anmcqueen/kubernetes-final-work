# Скрипт для автоматического создания кластера
# Установка Яндекс CLI
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc init

# Создание Network
yc vpc network create --name network-1 \
  --description "Sock Shop project network" \
  --folder-id enpncltd04hlh8fj75ba

# Создание кластера kubernetes (master)
yc managed-kubernetes cluster create \
  --name sock-shop-neo \
  --network-name network-1 \
  --zone ru-central1-a \
  --subnet-name network-1-ru-central1-a \
  --public-ip \
  --release-channel regular \
  --version 1.24 \
  --cluster-ipv4-range 192.168.0.0/20 \
  --service-ipv4-range 10.0.0.0/24 \
  --service-account-name kubernetes-account \
  --node-service-account-name kubernetes-account \
  --weekly-maintenance-window 'days=[saturday],start=00:00,duration=3h' \
  --enable-network-policy

# Добавление контекста кластера в kubeconfig '/home/ana/.kube/config'
yc managed-kubernetes cluster get-credentials sock-shop-neo --external

# Создание нод кластера kubernetes
yc managed-kubernetes node-group create \
  --cluster-name sock-shop-neo \
  --cores 4 \
  --core-fraction 100 \
  --weekly-maintenance-window 'days=[saturday],start=00:00,duration=3h' \
  --disk-size 64 \
  --disk-type network-hdd \
  --auto-scale min=1,max=2,initial=1 \
  --location zone=ru-central1-a,subnet-name=network-1-ru-central1-a \
  --memory 12\
  --name cluster-nodes \
  --network-acceleration-type standard \
  --platform-id standard-v3 \
  --public-ip \
  --container-runtime containerd \
  --version 1.24 \
  --metadata-from-file ssh-keys=/home/ana/.ssh/id_ed25519

# Подключение к кластеру sock-shop-neo
yc managed-kubernetes cluster \
  get-credentials sock-shop-neo \
  --external