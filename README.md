# Подготовка MVP инфраструктурной платформы для приложения Sock Shop
- Развернут кластер kubernetes при помощи Yandex Cloud: 1 master-node + 2 worker-node. 
- Установлены: ingress-nginx, cert-manager, argoCD, sock-shop, prometheus-operator, loki+promtail, grafana, hashicorp-vault; 

### Скрипты для создания кластера и сервисов (приложений)
1. **cluster-creation.sh** - скрипт, который создаст кластер из 1 мастер-ноды и 2 воркер-нод на платформе Yandex Cloud
2. **resource-installation.sh** - скрипт, который создаст объекты для всех необходимых микросервисов (ingress-nginx, cert-manager, argoCD, sock-shop, prometheus-operator, loki+promtail, grafana, hashicorp-vault;)

### Ссылки на ресурсы:
- Sock-shop - https://sock-shop.anynamefits.ru 
- ArgoCD - https://argocd.anynamefits.ru
- Grafana - https://grafana.anynamefits.ru
- Prometheus - https://prometheus.anynamefits.ru
- Vaunt - https://vault.anynamefits.ru

#### Скриншоты страниц можно посмотреть в папке screenshots 
![sock shop main page](https://github.com/anmcqueen/kubernetes-final-work/assets/126611281/c61b91e5-2c72-4a10-b451-c6870eb5b4d3)
