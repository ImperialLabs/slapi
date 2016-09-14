# Simple Lightweight API Bot (SLAPI)


## Prerequisites
You need Docker 1.10 or later installed.

## Getting started

### Bundler

run

    bundle install

(Optional) The project is set up with extra helpers for VS Code.  If you chose to use this then you should be able to run:

    bundle clean
    bundle install --binstubs --path vendor/bundle

And set breakpoints and debug.

### Running the server

To run sinatra locally simply run:

    rackup -p 4567

Which will use simple the thin server.

This should work in Visual Studio Code when selecting the `Sinatra` debug option, however sometimes it seems you need to restart all of Visual Studio Code.

### Running the docker container

To build the docker containter locally simply run:

    docker build --tag=slapi_local ./

NOTE: this will currently pull all of the development dependencies, need to revisit this.

To run the docker container:

    docker run -d -p 4567:4567 --name slapi_local slapi_local

## Development

### Testing

There are currently rspec integration tests using capybara.  These could use more help.

To run this tests simply:

    rspec

Since these are integration tests they will cause messages to be posted in a channel at imperiallabs.slack.com.

imperiallabs.slack.com is currently a free Slack team that you would need an invite to join.

To run all tests in Visual Studio Code use the `RSpec - all` configuration.

### Lint

Rubocop is being used. Try to keep the lint clean by either addressing the issues or updating the .rubocop.yml.

To run rubocop either run:

    rubocop

Or use a plugin in your favorite editor.



