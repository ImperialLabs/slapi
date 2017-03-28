# SLAPIN - API Example

## Prerequisites
-   Docker 1.10 or later

## Usage

### Build Locally

```bash
docker build --tag=slapin_api ./
```

### Run Externally

```bash
docker run -d -e BOT_URL=localhost:4567 -p 4700:4700 --name slapin_api slapin_api
```

```bash
docker run -d -v api.yml:/api/api.yml -p 4700:4700 --name slapin_api slapin_api
```

Config (api.yml)
```yaml
bot_url: '$url:$port'
```

### Run From Slapi

```yaml
plugin:
  type: api
  managed: true # Choose True or False for SLAPI management
  config:
    name: search # Name of instance
    Image: 'slapi/slapin_api' # Enter user/repo (standard docker pull procedures), you can also pull from a private repo via domain.com/repo
    ExposedPorts: 4700 # Expose a port or a range of ports inside the container.
    PortBindings:
      4700/tcp:
        - HostPort: '4700'
        - HostIp: '0.0.0.0'
    Tty: true # Set true/false for container TTY
    RestartPolicy: # https://docs.docker.com/engine/reference/run/#/restart-policies---restart
     Name: on-failure # no|always|unless-stopped are valid options. on-failure requires MaximumRetryCount
     MaximumRetryCount: 2 # Max number of time to attempt to restart container/plugin before quitting
```
### Access API Endpoints

```bash
curl -v -X GET localhost:4700/info
```
