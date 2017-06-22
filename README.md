# Simple Lightweight API Bot (SLAPI)

[![Travis](https://img.shields.io/travis/ImperialLabs/slapi.svg)](https://travis-ci.org/ImperialLabs/slapi) [![GitHub release](https://img.shields.io/github/release/ImperialLabs/slapi.svg)](Ihttps://github.com/ImperialLabs/slapi/releases) [![Code Climate](https://codeclimate.com/github/ImperialLabs/slapi/badges/gpa.svg)](https://codeclimate.com/github/ImperialLabs/slapi) [![Test Coverage](https://codeclimate.com/github/ImperialLabs/slapi/badges/coverage.svg)](https://codeclimate.com/github/ImperialLabs/slapi/coverage) [![Issue Count](https://codeclimate.com/github/ImperialLabs/slapi/badges/issue_count.svg)](https://codeclimate.com/github/ImperialLabs/slapi) [![Docker Pulls](https://img.shields.io/docker/pulls/slapi/slapi.svg)](https://hub.docker.com/r/slapi/slapi/) [![Docker Stars](https://img.shields.io/docker/stars/slapi/slapi.svg)](https://hub.docker.com/r/slapi/slapi/)

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Simple Lightweight API Bot (SLAPI)](#simple-lightweight-api-bot-slapi)
	- [Prerequisites](#prerequisites)
	- [What is SLAPI?](#what-is-slapi)
	- [Quick Start](#quick-start)
		- [Step by Step Guide](#step-by-step-guide)
		- [Local](#local)
		- [Docker](#docker)
		- [Hello World Your Heart Out!](#hello-world-your-heart-out)
	- [Usage](#usage)
		- [Docker Setup](#docker-setup)
		- [Bundler](#bundler)
			- [Global Install](#global-install)
			- [Project Local Install](#project-local-install)
		- [Configuration](#configuration)
- [Adapter Settings](#adapter-settings)
- [Bot ConfigFile](#bot-configfile)
- [Admin Settings](#admin-settings)
- [Help Settings](#help-settings)
		- [Running the server](#running-the-server)
			- [Local](#local)
			- [Running w/ Docker](#running-w-docker)
				- [CLI w/ Mounted Sock Port](#cli-w-mounted-sock-port)
				- [Docker Compose w/ DinD](#docker-compose-w-dind)
	- [Bot Anatomy](#bot-anatomy)
	- [API](#api)
	- [Brain](#brain)
	- [Plugins](#plugins)
	- [Rake Tasks](#rake-tasks)
		- [Run Bot](#run-bot)
		- [Integration Tests](#integration-tests)
		- [Cleanup](#cleanup)
	- [Development](#development)
		- [Quick Dev](#quick-dev)
		- [Ruby Setup](#ruby-setup)
			- [rbenv](#rbenv)
				- [Install](#install)
				- [Configure](#configure)
			- [RVM](#rvm)
		- [Testing](#testing)
			- [Local Testing](#local-testing)
			- [Remote Testing (Docker)](#remote-testing-docker)
				- [Mounted Socks](#mounted-socks)
				- [Compose & DinD](#compose-dind)
			- [Attaching Debugger to Docker](#attaching-debugger-to-docker)
		- [Linting](#linting)
	- [How to Contribute](#how-to-contribute)
		- [External Contributors](#external-contributors)
		- [Internal Contributors](#internal-contributors)

<!-- /TOC -->

## Prerequisites

-   Slack Team & Ability to Add Custom Integrations
-   Docker 1.10 or later - See [Docker](#docker-setup) section for more info
-   Ruby 2.3 or later - See [Ruby](#ruby-setup) section for options
-   Bundler - See [Bundler](#bundler) Section

## What is SLAPI?

SLAPI is our concept of a Slack bot. It's blind to languages. While it may be written in Ruby and using Sinatra for it's API interface, it does not care what you use for your plugins.

If you can stick it in a Docker Container or Slap an API on it, you can make it a plugin. (We refer to them as SLAPINs)

SLAPI is in the early stages, we just released the MVP. There is no pre-existing plugins, yet (give us time!). Just [examples](https://github.com/ImperialLabs/slapi/tree/master/examples) and [test](https://github.com/ImperialLabs/slapin-test) plugins for references.

Check out the getting started below and feel free to open an issue for anything, even if you just want us to explain a little more about something.

## Quick Start

### Step by Step Guide

Head over to [Here](https://imperiallabs.github.io/quick_landing.html) for a walk through of the basics getting started

### Local

**IMPORTANT:** Make sure you have looked at [Prerequisites](#prerequisites) first

There are rake tasks created to make this quick to get started.

Running either will create a bot.local.yml file with the exported key and give the most basic configuration.

```bash
git clone https://github.com/ImperialLabs/slapi.git
cd slapi
export SLACK_TOKEN=xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT
bundle install --binstubs --path vendor/bundle
bundle exec rake local
```
### Docker

**IMPORTANT:** Make sure you have looked at [Prerequisites](#prerequisites) first

```bash
git clone https://github.com/ImperialLabs/slapi.git
cd slapi
export SLACK_TOKEN=xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT
rake docker
```

### Hello World Your Heart Out!
Here's a quick script plugin to get you out the door, kick the tires and give it a go!

just place this in the `./config/plugins/` folder as whatever name you wish to use for it in the bot (e.g. `hello.yml`)
```yaml
plugin:
    type: script
    language: bash
    listen_type: passive
    help:
      world: "Says Hello World!"
    description: "simple hello world"
    write: |
      #!/bin/bash
      if [ "${1}" == 'world' ]; then
          echo 'Hello World!'
      else
          echo 'No World for You!'
      fi
```

## Usage

### Docker Setup

Docker must be installed for the bot to work.

-   Windows Install - <https://docs.docker.com/docker-for-windows/install/>
-   OSX Install - <https://docs.docker.com/docker-for-mac/install/>
-   Linux Install - <https://docs.docker.com/engine/installation/#time-based-release-schedule> (See Docker for Linux on left Side)
    -   **Important:** If running in Linux, ensure user running SLAPI can run docker, check by running `docker ps`
    -   To enable a user to run docker without sudo go here <https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user>

### Bundler

#### Global Install

Run the following

```bash
gem install bundler
bundle install
```

#### Project Local Install

The project is set up with extra helpers for VS Code. If you chose to use this then you should be able to run:

```bash
gem install bundler
bundle install --binstubs --path vendor/bundle
```

### Configuration

You will need a bot configuration from Slack. See: <https://api.slack.com/bot-users>

Once you have configured a bot then you will have a token like: "xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT"

You will need to put this in the file config/bot.yml or config/bot.local.yml for example:

**NOTE:** any .local.yml or .test.yml files are automatically ignored by git or docker

```yaml
# Adapter Settings
adapter:
  type: slack # Enables option alternative adapters
  token: # API token
  ## Coming Soon ##
  # user_agent: # User-agent, defaults to Slack Ruby Client/version.
  # proxy: # Optional HTTP proxy.
  # ca_path: # Optional SSL certificates path.
  # ca_file: # Optional SSL certificates file.
  # endpoint: # Slack endpoint, default is https://slack.com/api.
  # logger: # Optional Logger instance that logs HTTP requests.

# Bot ConfigFile
bot:
  name: bot # name for bot to respond to (optional)

# Admin Settings
admin:
  users: # Array of names or IDs who are admins
  dm_limit: # True/False Limits bot DMs, will not respond to DMs from non-admins.

# Help Settings
help:
  level: 1 # 1/2; 1 only lists plugin names, 2 lists names and opts
  dm_user: false # True/False; True to send all help requests as DM, false to post in room

plugins:
  location: '../../config/plugins/'
```

### Running the server

#### Local

To run Sinatra simply run:

If using [Global](#global-install)

```bash
rackup -p 4567
```
If using [Project](#project-local-install)

```bash
bundle exec rackup -p 4567
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

## Bot Anatomy

Overview of how the bot is put together and what's available for use

## API

SLAPI has several API endpoints available to plugins and/or applications.

See more in depth documentation [here](https://imperiallabs.github.io/api_landing.html)

-   Chat:
    -   Speak: Simple post to chat options
    -   Attachment: Formatted Data posted to chat (Title, Text)
    -   Emote: Post to chat as emote
    -   Ping: receive a pong
-   Brain:
    -   Save: Save data into bot brain
    -   Delete: Delete data from bot brain
    -   Query_Key: Search for a key value in bot brain
    -   Query Hash: Search for all keys in bot brain, each plugin has it's own hash
-   Plugin:
    -   Reload: Can call a reload of plugins without restart bot

## Brain

SLAPI utilizes redis for the bot brain.

Brain is only accessible via API for plugins

See more in depth documentation [here](https://imperiallabs.github.io/brain_landing.html)

## Plugins

SLAPI has 3 different types of plugin options.

See more in depth documentation [here](https://imperiallabs.github.io/plugins_landing.html)

-   Script:
    -   Allows just utilizing a simple script as a plugin
    -   Currently supports the following languages: Shell/Bash, Ruby, Python, NodeJS
    -   Has two data options
        -   Simple: passes the `hello world` from `@bot say hello world` to container as exec
        -   All: passes the entire json blob to container as exec.
-   Container:
    -   Allows the use of any language or app that can run in docker on linux
    -   Has two data options
        -   Simple: passes the `hello world` from `@bot say hello world` to container as exec
        -   All: passes the entire json blob to container as exec.
-   API:
    -   Allows use of anything that can be called by API
    -   Requires to specific endpoints for SLAPI
        -   Info Endpoint: Provide the data to build the bot help
        -   Command Endpoint: Configurable endpoint for SLAPI to post a json payload to with all the information from slack

## Rake Tasks

We have built a rake file to help wrap some of the madness

Just run `rake` or `bundle exec rake` for a current list of tasks

### Run Bot

Both quick options require a `export SLACK_TOKEN=xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT`

There are two quick options here
-   local
    -   Creates a bot.local.yml with the exported Slack Token
    -   Runs a local bot using rackup in production mode
-   docker
    -   Creates a bot.local.yml with the exported Slack Token
    -   Runs compose to setup the latest version in dockerhub

You can also just use to avoid creating a bot config
-   run:local_prod or run:local_dev (if you want debug)
-   run:docker

### Integration Tests
**Important** Must be a token from the http://imperiallabs.slack.com/

Quick Option
Requires a `export SLACK_TOKEN=xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT`
-   integration
    -   Creates a bot.local.yml with the exported Slack Token
    -   Runs a local bot using rackup in production mode

Again, to avoid bot config creation just do
-   integration:spec

### Cleanup

If you just want to clear out the cruft (scripts, bot.test.yml, bundle clean)
-   cleanup

## Development

### Quick Dev

**IMPORTANT:** Make sure you have looked at [Prerequisites](#prerequisites) first

When just want to absolutely just run the integration tests

```bash
git clone https://github.com/ImperialLabs/slapi.git
cd slapi
export SLACK_TOKEN=xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT
bundle install --binstubs --path vendor/bundle
bundle exec rake integration
```

### Ruby Setup
Quick install/config Instructions for rbenv or rvm as there is a visual studio launch.json included that supports both for debugging

#### rbenv

##### Install

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo "gem: --no-document" > ~/.gemrc #(optional)

cat >> '~/.bashrc' << 'EOF'
if [ -d "~/.rbenv" ]; then
     export PATH="$HOME/.rbenv/bin:$PATH"
fi

EOF

cat >> '~/.bashrc' << 'EOF'
rbenv ()
{
    local command;
    command="$1";
    if [ "$#" -gt 0 ]; then
        shift;
    fi;
    case "$command" in
        rehash | shell)
            eval "$(rbenv "sh-$command" "$@")"
        ;;
        *)
            command rbenv "$command" "$@"
        ;;
    esac
}

EOF

cat >> '~/.bashrc' << 'EOF'
eval "$(rbenv init -)"

EOF
```
##### Configure

Install whatever version you wish as long as it's greater than 2.3

```
rbenv install 2.3.3
rbenv global 2.3.3
```

#### RVM

You will need to install bundler on the default gemset (even if you work on another gemset) to not have to change the launch.json for VSCode.

So for whatever ruby you are working on:

```
rvm gemset use default
gem install bundler
```

The reason for this is so that the `"pathToBundler": "${env.HOME}/.rvm/gems/${env.rvm_ruby_string}/wrappers/bundle"` does not need to change as you switch rubies.

At the time of this writing, since this is using beta versions of the debugger and has many latest libraries that are interdependent, you may have to run:

```
gem update —system
rm -rf vendor/bundle
bundle install --binstubs --path vendor/bundle
```
To get the latest RubyGems.

### Testing

#### Local Testing

There are currently rspec integration tests using capybara. These could use more help.

To run this tests simply:

```bash
rspec
```

Since these are integration tests they will cause messages to be posted in a channel at imperiallabs.slack.com.

imperiallabs.slack.com is currently a free Slack team that you would need an invite to join.

Ensure you have followed all the tasks in [Bundler Section](#bundler)

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

-   [Fork](https://github.com/ImperialLabs/slapi#fork-destination-box) the repo on GitHub
-   Clone the project to your own machine
-   Commit changes to your own branch
-   Push your work back up to your fork
-   Submit a Pull Request so that we can review your changes

**NOTE**: Be sure to merge the latest from "upstream" before making a pull request!

### Internal Contributors

-   Clone the project to your own machine
-   Create a new branch from master
-   Commit changes to your own branch
-   Push your work back up to your branch
-   Submit a Pull Request so the changes can be reviewed

**NOTE**: Be sure to merge the latest from "upstream" before making a pull request!
