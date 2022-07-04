# Traefik and Portainer on Docker Swarm with Letsencrypt

Reproducing a Traefik with SSL and Portainer setup on a 2 Node Docker Swarm

## Install Docker:

Install Docker on both nodes with a Bootstrap Script:

```
$ curl https://gitlab.com/rbekker87/scripts/raw/master/setup-docker-ubuntu.sh | bash
```

## Initialize the Swarm

Initialize Swarm on Manager (node-1):

```
$ docker swarm init --advertise-addr ens3
Swarm initialized: current node (jhs46c7mv0vl86v488joqazpd) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-3kgazh7s0aebjgov5tw0s85d0oz1wu4whefibiszaiuij7f7ub-3ocy5sathgputnxzpjacfypip 10.163.68.18:2377
```

Join Worker Node to the Swarm (node-2):

```
$ docker swarm join --token SWMTKN-1-3kgazh7s0aebjgov5tw0s85d0oz1wu4whefibiszaiuij7f7ub-3ocy5sathgputnxzpjacfypip 10.163.68.18:2377
This node joined a swarm as a worker.
```

List nodes from the Manager (node-1):

```
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
jhs46c7mv0vl86v488joqazpd *   docker1             Ready               Active              Leader              18.09.7
3bzwcuokvfi7w3gitfturzw93     docker2             Ready               Active                                  18.09.7
```

## DNS

Setup a A Record to the Manager IP:
- `meikel.rbkr.xyz` -> `185.136.234.52`

Setup a Wildcard Record with the value of CNAME to the previous record:
- `*.meikel.rbkr.xyz` -> `meikel.rbkr.xyz`

Testing:

```
$ dig A meikel.rbkr.xyz +short
185.136.234.52

$ dig CNAME test.meikel.rbkr.xyz +short
meikel.rbkr.xyz.
```

## Provision Traefik:

Create the compose file for treafik `docker-compose.traefik.yml`:

```
version: '3.7'
services:
  traefik:
    image: traefik:latest
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
    command: >
      --api
      --acme
      --acme.storage=/certs/acme.json
      --acme.entryPoint=https
      --acme.httpChallenge.entryPoint=http
      --acme.onHostRule=true
      --acme.onDemand=false
      --acme.acmelogging=true
      --acme.email=${EMAIL:-root@localhost}
      --docker
      --docker.swarmMode
      --docker.domain=${DOMAIN:-localhost}
      --docker.watch
      --defaultentrypoints=http,https
      --entrypoints='Name:http Address::80'
      --entrypoints='Name:https Address::443 TLS'
      --logLevel=INFO
      --accessLog
      --metrics
      --metrics.prometheus
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - traefik_certs:/certs
    configs:
      - source: traefik_htpasswd
        target: /etc/htpasswd
    networks:
      - public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
      labels:
        - "traefik.docker.network=public"
        - "traefik.port=8080"
        - "traefik.backend=traefik"
        - "traefik.enable=true"
        - "traefik.frontend.rule=Host:traefik.${DOMAIN:-localhost}"
        - "traefik.frontend.auth.basic.usersFile=/etc/htpasswd"
        - "traefik.frontend.headers.SSLRedirect=true"
        - "traefik.frontend.entryPoints=http,https"

configs:
  traefik_htpasswd:
    file: ./htpasswd

networks:
  public:
    driver: overlay
    name: public

volumes:
  traefik_certs: {}
```

Install dependency to create basic auth file:

```
sudo apt install apache2-utils -y
```

Create admin/admin credentials:

```
$ htpasswd -c htpasswd admin
New password:
Re-type new password:
Adding password for user admin
```

Set the domain and reachable email as environment variable:

```
$ export DOMAIN=meikel.rbkr.xyz
$ export EMAIL=your@email-domain.com
```

Deploy the traefik stack:

```
$ docker stack deploy -c docker-compose.traefik.yml proxy
Creating network public
Creating config proxy_traefik_htpasswd
Creating service proxy_traefik
```

List the service:

```
$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
c4cm18zspces        proxy_traefik       replicated          1/1                 traefik:latest
```

Access the Traefik UI on `https://traefik.meikel.rbkr.xyz`

![image](https://user-images.githubusercontent.com/50801771/60624475-b0281800-9de5-11e9-861d-9cc121144b20.png)

## Portainer

Create the compose `docker-compose.portainer.yml`

```
version: '3.7'

services:
  agent:
    image: portainer/agent
    environment:
      AGENT_CLUSTER_ADDR: tasks.agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - private
    deploy:
      mode: global
      placement:
        constraints:
          - node.platform.os == linux

  portainer:
    image: portainer/portainer
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer-data:/data
    networks:
      - private
      - public
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.frontend.rule=Host:portainer.${DOMAIN}
        - traefik.enable=true
        - traefik.port=9000
        - traefik.tags=public
        - traefik.docker.network=public
        - traefik.redirectorservice.frontend.entryPoints=http
        - traefik.redirectorservice.frontend.redirect.entryPoint=https
        - traefik.webservice.frontend.entryPoints=https

networks:
  private:
    driver: overlay
    name: private
  public:
    external: true

volumes:
  portainer-data: {}
```

Make sure the DOMAIN environment variable is still set:

```
$ env | grep DOMAIN
DOMAIN=meikel.rbkr.xyz
```

Deploy the stack:

```
$ docker stack deploy -c docker-compose.portainer.yml portainer
Creating network private
Creating service portainer_agent
Creating service portainer_portainer
```

Check if all the containers has checked in for the respective services:

```
$ docker service ls
ID                  NAME                  MODE                REPLICAS            IMAGE                        PORTS
wwu7alr6ysw0        portainer_agent       global              2/2                 portainer/agent:latest
09flw7vt80r7        portainer_portainer   replicated          1/1                 portainer/portainer:latest
c4cm18zspces        proxy_traefik         replicated          1/1                 traefik:latest
```

Portainer should show up on the Traefik UI as a Frontend and Backend:

![image](https://user-images.githubusercontent.com/50801771/60625061-0f3a5c80-9de7-11e9-85d0-8b0037e5155a.png)

Accessing Portainer on `https://portainer.meikel.rbkr.xyz`:

![image](https://user-images.githubusercontent.com/50801771/60625344-d5b62100-9de7-11e9-9eaf-d3caed0a368d.png)

After setting up the user:

![image](https://user-images.githubusercontent.com/50801771/60625431-1746cc00-9de8-11e9-8b89-3b430dbe2a96.png)

And having a look at the services:

![image](https://user-images.githubusercontent.com/50801771/60625507-507f3c00-9de8-11e9-8c50-39f4cf013d00.png)

