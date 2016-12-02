# Simple Lightweight API Bot (SLAPI)

[![Travis](https://img.shields.io/travis/ImperialLabs/slapi.svg)](https://travis-ci.org/ImperialLabs/slapi) [![Stories in Ready](https://badge.waffle.io/ImperialLabs/slapi.png?label=ready&title=Ready)](https://waffle.io/ImperialLabs/slapi) [![Docker Automated buil](https://img.shields.io/docker/automated/slapi/slapi.svg)](https://hub.docker.com/r/slapi/slapi/) [![Docker Pulls](https://img.shields.io/docker/pulls/slapi/slapi.svg)](https://hub.docker.com/r/slapi/slapi/) [![Docker Stars](https://img.shields.io/docker/stars/slapi/slapi.svg)](https://hub.docker.com/r/slapi/slapi/) [![GitHub release](https://img.shields.io/github/release/slapi/slapi.svg)](https://github.com/ImperialLabs/slapi/releases) [![Github Releases](https://img.shields.io/github/downloads/slapi/slapi/latest/total.svg)](https://github.com/ImperialLabs/slapi/releases)

## Prerequisites

* Docker 1.10 or later
* Ruby 2.2 or laterπ

## Getting started

### Bundler

run

```bash
bundle install
```

(Optional) The project is set up with extra helpers for VS Code. If you chose to use this then you should be able to run:

```bash
bundle clean
bundle install --binstubs --path vendor/bundle
bundle clean
```

And set breakpoints and debug.

### configuration

You will need a bot configuration from Slack. See: <https://api.slack.com/bot-users>

Once you have configured a bot then you will have a token like: "xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT"

You will need to put this in the file config/bot.yml or config/bot.local.yml for example:

**NOTE:** any .local.yml files are automatically ignored by git or docker

```yaml
# Adapter Settings
adapter:
  type: slack
  token: "xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT"
  ## Future Options
  # user_agent: # User-agent, defaults to Slack Ruby Client/version.
  # proxy: # Optional HTTP proxy.
  # ca_path: # Optional SSL certificates path.
  # ca_file: # Optional SSL certificates file.
  # endpoint: # Slack endpoint, default is https://slack.com/api.
  # logger: # Optional Logger instance that logs HTTP requests.

# Bot ConfigFile
bot:
  name: myawesomebot # Enables calling bot with @bot or if you wanted a secondary name to respond to

# Admin Settings
# Future Options
admin:
  users: # Array of names or IDs who are admins
  dm_limit: # True/False Limits bot DMs, will not respond to DMs from non-admins.

# Help Settings
# Future Options
help:
  level: 1 # 1/2; 1 only lists plugin names, 2 lists names and opts
  dm_user: false # True/False; True to send all help requests as DM, false to post in room
```

### Running the server

#### Local

To run Sinatra locally simply run:

```bash
rackup -p 4567
```

Which will use simple the thin server.

This should work in Visual Studio Code when selecting the `Sinatra` debug option, however sometimes it seems you need to restart all of Visual Studio Code.

When running in Visual Studio Code, Sinatra tends to run on port 9292.

The settings for Visual Studio Code can be found in the `launch.json` file.

#### Running w/ Docker

To build the docker container locally simply run:

```bash
docker build --tag=slapi_local ./
```

##### CLI w/ Mounted Sock Port

Run with SLAPI using localhost Docker for Plugins

To run the docker container:

**NOTE**: This will only work on Linux or OSX Based Hosts

**NOTE**:Running without a config attached your bot will not connect you may want to add a `-v /path/to/config:/usr/src/slapi/config` or run `docker exec -it slapi_local bash` and manually edit one for testing.

```bash
docker run -d -p 4567:4567 -v /var/run/docker.sock:/var/run/docker.sock --name slapi_local slapi_local
```

To run a released version:

```bash
docker run -d -p 4567:4567 -v /var/run/docker.sock:/var/run/docker.sock --name slapi slapi/slapi:latest
```

Run w/ Config files:

```bash
docker run -d -p 4567:4567 -v /var/run/docker.sock:/var/run/docker.sock -v /path/to/config:/usr/src/slapi/config --name slapi slapi/slapi:latest
```

##### Docker Compose w/ DinD

This setup should work on all Operating Systems supported by Docker

Run the standard compose file [docker-compose.yml](docker-compose.yml) inside the root of the project

Pulls Latest SLAPI Build and mounts the local ./config directory for bot configs. Change the compose file as needed.

```bash
docker-compose up
```

Build SLAPI container from scratch w/ compose.

```bash
docker-compose -f slapi-build-compose.yml up
```

## Development

### Testing

#### Local Testing

There are currently rspec integration tests using capybara. These could use more help.

To run this tests simply:

```bash
rspec
```

Since these are integration tests they will cause messages to be posted in a channel at imperiallabs.slack.com.

imperiallabs.slack.com is currently a free Slack team that you would need an invite to join.

Ensure you have followed all the tasks in [Bundler Section](#Bundler)

To run all tests in Visual Studio Code use the `RSpec - all` configuration.

Select `Sinatra-rbenv` or `Sinatra-rvm` in VS Code depending on your setup to do standard debugging.

Or use a plugin in your favorite editor.

#### Remote Testing (Docker)

If Making changes to the Dockerfile and/or container itself build your changes by running:

```bash
docker build --tag=slapi_local ./
```

##### Mounted Socks

Run with SLAPI using localhost Docker for Plugins

To run the docker container:
**NOTE**: This will only work on Linux or OSX Based Hosts

To run the docker container:

```bash
docker run -d -p 4567:4567 -v /var/run/docker.sock:/var/run/docker.sock --name slapi_local slapi_local
```

##### Compose & DinD

This setup should work on all Operating Systems supported by Docker

Utilizes the image built previously, this is probably the option you want to use for windows. There has been issues getting docker-compose to build images on windows, so utilize the build option under [Remote Testing](#Remote-Testing) header.

```bash
docker-compose -f slapi-dev-prebuilt-compose.yml up
```

Build SLAPI container/image from scratch w/ compose.

```bash
docker-compose -f slapi-dev-compose.yml up
```

#### Attaching Debugger to Docker

The debuggers run on port 1234, so just connect to `127.0.0.1:1234`

If you are using VS Code, you can select the `Attach to Docker` profile in the debugger.

### Linting

Rubocop is being used. Try to keep the lint clean by either addressing the issues or updating the .rubocop.yml.

To run rubocop either run:

```bash
rubocop
```

## How to Contribute

### External Contributors

* [Fork](https://github.com/ImperialLabs/slapi#fork-destination-box) the repo on GitHub
* Clone the project to your own machine
* Commit changes to your own branch
* Push your work back up to your fork
* Submit a Pull Request so that we can review your changes

**NOTE**: Be sure to merge the latest from "upstream" before making a pull request!

### Internal Contributors

* Clone the project to your own machine
* Create a new branch from master
* Commit changes to your own branch
* Push your work back up to your branch
* Submit a Pull Request so the changes can be reviewed

**NOTE**: Be sure to merge the latest from "upstream" before making a pull request!