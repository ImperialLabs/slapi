# Simple Lightweight API Bot (SLAPI)


## Prerequisites
You need Docker 1.10 or later installed.

## Getting started

To run sinatra locally 

## Development

### Bundler

run

    bundle install

(Optional) The project is set up with extra helpers for VS Code.  If you chose to use this then you should be able to run:

    bundle clean
    bundle install --binstubs --path vendor/bundle

And set breakpoints and debug.

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



