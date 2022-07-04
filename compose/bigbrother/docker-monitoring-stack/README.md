# Docker Containers Monitoring

A monitoring solution for Docker hosts and containers with [Prometheus](https://prometheus.io/), [Grafana](http://grafana.org/), [cAdvisor](https://github.com/google/cadvisor),
[NodeExporter](https://github.com/prometheus/node_exporter) and alerting with [AlertManager](https://github.com/prometheus/alertmanager).

## Deploy

Clone this repository on your Docker host, cd into docker-monitoring-stack directory and run compose up:

```bash
git clone https://github.com/SamirNabadov/docker-monitoring-stack.git
cd docker-monitoring-stack

export ADMIN_USER=admin
export ADMIN_PASSWORD=admin
export ADMIN_PASSWORD_HASH=JDJhJDE0JE91S1FrN0Z0VEsyWmhrQVpON1VzdHVLSDkyWHdsN0xNbEZYdnNIZm1pb2d1blg4Y09mL0ZP

docker-compose up -d
```
