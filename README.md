# Simple Lightweight API Bot (SLAPI)

[![Stories in Ready](https://badge.waffle.io/ImperialLabs/slapi.png?label=ready&title=Ready)](https://waffle.io/ImperialLabs/slapi)

## Prerequisites

* Docker 1.10 or later
* Ruby 2.2 or later

## Getting started

### Bundler

run

```
bundle install
```

(Optional) The project is set up with extra helpers for VS Code. If you chose to use this then you should be able to run:

```
bundle clean
bundle install --binstubs --path vendor/bundle
bundle clean
```

And set breakpoints and debug.

### configuration

You will need a bot configuration from Slack. See: <https://api.slack.com/bot-users>

Once you have configured a bot then you will have a token like: "xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT"

You will need to put this in the file config/bot.yml or config/bot.local.yml for example:

**Note:** any .local.yml files are automatically ignored by git or docker

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

To run Sinatra locally simply run:

```
rackup -p 4567
```

Which will use simple the thin server.

This should work in Visual Studio Code when selecting the `Sinatra` debug option, however sometimes it seems you need to restart all of Visual Studio Code.

When running in Visual Studio Code, Sinatra tends to run on port 9292.

The settings for Visual Studio Code can be found in the `launch.json` file.

### Running the docker container

To build the docker container locally simply run:

```
docker build --tag=slapi_local ./
```

NOTE: this will currently pull all of the development dependencies, need to revisit this.

To run the docker container:

```
docker run -d -p 4567:4567 -p 80:80 --name slapi_local slapi_local
```

## Development

### Testing

There are currently rspec integration tests using capybara. These could use more help.

To run this tests simply:

```
rspec
```

Since these are integration tests they will cause messages to be posted in a channel at imperiallabs.slack.com.

imperiallabs.slack.com is currently a free Slack team that you would need an invite to join.

Ensure you have followed all the tasks in [Bundler Section](### Bundler)

To run all tests in Visual Studio Code use the `RSpec - all` configuration.

Select `Sinatra-rbenv` or `Sinatra-rvm` in VS Code depending on your setup to do standard debugging.

### Lint

Rubocop is being used. Try to keep the lint clean by either addressing the issues or updating the .rubocop.yml.

To run rubocop either run:

```
rubocop
```

Or use a plugin in your favorite editor.
