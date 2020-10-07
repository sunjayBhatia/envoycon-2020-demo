This demo is a modified version of [this sample](https://github.com/davinci26/windows-envoy-samples), based on the [Envoy front proxy sandbox example](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/front_proxy) presented at EnvoyCon 2020 in a [talk introducing Windows support in Envoy](https://sched.co/ecca)

In this demo we use Envoy and Docker composewith Windows Server Core containers to split traffic between two services, implement (m)TLS between Envoy instances, and demonstrate dynamic configuration reload. This setup is intended to mimic a potential common cloud-native deployment structure in Kubernetes or another container orchestrator.

A diagram of the resulting deployment structure is below:

![Architecture](./assets/envoy-demo.png)

The frontend Envoy is initally configured to run in a container with a listener on port 8000 (mapped to 3000 on the host) and two upstream clusters. The frontend listener is set up to serve TLS and the backend cluster configuration is set up to perform mTLS with the upstream services. The listener and cluster configuration are set up as a dynamic configuration files so they can be modified and reloaded on the fly. The Envoy admin API is made available as well.

Each of the service instances are set up as a container running a simple static Flask app alongside an Envoy instance. This structure is analagous to a Kubernetes pod/container sidecar with shared network compartment archictecture. The service Envoy alongside each app is configured with a dynamic listener (that can be reloaded similar to the frontend Envoy) and static upstream cluster pointing to the Flask app. For demo purposes, the listener and admin endpoints for the service instance Envoys are made available via port mappings to the host.

Envoy configuration and certificates are mounted in the running service containers and can be copied/edited/moved on the host to do dynamic updates. Self-signed certificates for TLS were generated with the [certstrap CLI](https://github.com/square/certstrap)

#### Requirements

- [ ] Docker for Windows and Docker compose
- [ ] Envoy proxy static executable built from source
- [ ] A Windows (Server) instance capable of running LTS Windows 2019 container images (Windows OS version 10.0.17763.1457)

#### Run the demo

1. Make sure that `envoy-proxy.exe` is inside the local directory:

``` Powershell
PS C:\workspace\envoycon-2020-demo> Test-Path .\envoy-static.exe
True
```

2. Check that Docker is installed and running:

``` Powershell
PS C:\workspace\envoycon-2020-demo> docker version
Client: Docker Engine - Enterprise
 Version:           19.03.11
 API version:       1.40
 Go version:        go1.13.11
 Git commit:        0da829ac52
 Built:             06/26/2020 17:20:46
 OS/Arch:           windows/amd64
 Experimental:      false

Server: Docker Engine - Enterprise (this node is not a swarm manager - check license status on a manager node)
 Engine:
  Version:          19.03.11
  API version:      1.40 (minimum version 1.24)
  Go version:       go1.13.11
  Git commit:       0da829ac52
  Built:            06/26/2020 17:19:32
  OS/Arch:          windows/amd64
  Experimental:     false
```

3. Ensure `docker-compose` is installed

```Powershell
PS C:\workspace\envoycon-2020-demo> Get-Command docker-compose

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Application     docker-compose.exe                                 0.0.0.0    C:\Program Files\Docker\docker-compose.exe

```

4. Build and start the services

``` Powershell
PS C:\workspace\envoycon-2020-demo> docker-compose build --pull
PS C:\workspace\envoycon-2020-demo> docker-compose up -d
PS C:\workspace\envoycon-2020-demo> docker-compose ps
PS C:\workspace\envoycon-2020-demo> docker-compose ps
              Name                            Command               State                       Ports
--------------------------------------------------------------------------------------------------------------------------
envoycon-2020-demo_cat-service_1   cmd /S /C powershell ./ser ...   Up      0.0.0.0:3002->8000/tcp, 0.0.0.0:8083->8081/tcp
envoycon-2020-demo_dog-service_1   cmd /S /C powershell ./ser ...   Up      0.0.0.0:3001->8000/tcp, 0.0.0.0:8082->8081/tcp
envoycon-2020-demo_front-envoy_1   envoy-static.exe -c ./envo ...   Up      0.0.0.0:3000->8080/tcp, 0.0.0.0:8081->8081/tcp
```

5. Test the running services

* Visit `localhost:3000` to see the pets website. If you refresh you should see the traffic going sometimes to service 1 and sometimes to service 2.
* Visit `localhost:8081` to see Envoy admin page and the collected stats.

6. Perform a dynamic configuration reload

* Copy one of the `listeners.yaml` or `clusters.yaml` files to a temporary location
* Make some configuration modifications
  * Update percentage of traffic routed to each backend
  * Change certificates, validation context to test out rotation, mTLS
* Move the temporary file back to the original name

```Powershell
PS C:\workspace\envoycon-2020-demo> cp .\service-envoy-config\listeners.yaml .\service-envoy-config\listeners.tmp.yaml
...
Configuration modifications
...
PS C:\workspace\envoycon-2020-demo> mv -Force .\service-envoy-config\listeners.tmp.yaml .\service-envoy-config\listeners.yaml
```
