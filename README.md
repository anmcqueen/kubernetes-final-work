# Подготовка MVP инфраструктурной платформы для приложения Sock Shop
- Развернут кластер kubernetes при помощи Yandex Cloud: 1 master-node + 2 worker-node. 
- Установлены:
  1. sock-shop - само приложение, 
  2. ingress-nginx - Ingress-сервис,
  3. cert-manager - Контроллер сертификатов,
  4. argoCD - CI/CD сервис,
  5. prometheus-operator, loki+promtail, grafana - Cервисы для мониторинга и логирования,
  6. hashicorp-vault - Хранилище секретов
  
### Чтобы развернуть аналогичную инфраструктуру, необходимо прогнать скрипты для создания кластера и сервисов (приложений):
1. Cкрипт, который создаст кластер из 1 мастер-ноды и 2 воркер-нод на облачной платформе Yandex Cloud: **cluster-creation.sh**

    `sh cluster-creation.sh`

2. Cкрипт, который создаст объекты для всех необходимых микросервисов (ingress-nginx, cert-manager, argoCD, sock-shop, prometheus-operator, loki+promtail, grafana, hashicorp-vault;): **resource-installation.sh**. Скрипт дополнен комментариями.
   Примечания:
   - Команды из этого скрипта предлагается запускать поочередно, а не весь скрипт сразу.
   - Если установите ArgoCD и настроите в нем Application для sock-shop, то разворачивать руками sock-shop не нужно, это сделает ArgoCD. Команды для ручной установки sock-shop приведены на случай использования конфигурации без ArgoCD.

### Интеграция с CI/CD сервисом
- Используемый сервис - ArgoCD https://argocd.anynamefits.ru
- ArgoCD подключен к текущему репозиторию git@github.com:anmcqueen/kubernetes-final-work.git
- В ArgoCD создан Application "sock-shop-helm". Он создается путем применения конфига ./argoCD/argoCD-application-helm.yaml
- В результате применения конфига ./argoCD/argoCD-application-helm.yaml ArgoCD будет настроен на **ручную** синхронизацию ресурсов. Т.е., чтобы микросервисы для sock-shop создались, в веб-интерфейсе необходимо прожать Sync. Аналогично при изменения шаблонов или values для sock-shop синхронизацию необходимо будет прожимать ручками.
- Чтобы настроить автоматическую синхронизацию, в настройках вашего Application включите Auto-sync: 
![argoCD_enableAutoSync](https://github.com/anmcqueen/kubernetes-final-work/assets/126611281/d65cbc1b-43d7-4630-901f-032e0ffaa0b4)

### Мониторинг и логирование
- Мониторинг и логирование настроены с помощью следующих ресурсов:
- Prometheus-operator собирает метрики приложений. Для сбора метрик sock-shop созданы объекты ServiceMonitors, данные от которых забирает prometheus-operator
- Loki + promtail отвечают за сбор логов приложений. Promtail - это агент, ответственный за сбор логов и отправку их в Loki, а Loki, в свою очередь, отвечает за хранение логов и обработку запросов.
- Grafana - инструмент визуализации данных. В Grafana настроены 2 DataSources: Prometheus и Loki.
- Дашборды для Grafana лежат в папке ./monitoring/dashboards в виде json-файлов, их можно импортировать. 

### Ссылки на ресурсы:
- Sock-shop - https://sock-shop.anynamefits.ru 
- ArgoCD - https://argocd.anynamefits.ru
- Grafana - https://grafana.anynamefits.ru
- Prometheus - https://prometheus.anynamefits.ru
- Vaunt - https://vault.anynamefits.ru

#### Скриншоты страниц можно посмотреть в папке ./screenshots 
![sock shop main page](https://github.com/anmcqueen/kubernetes-final-work/assets/126611281/c61b91e5-2c72-4a10-b451-c6870eb5b4d3)
