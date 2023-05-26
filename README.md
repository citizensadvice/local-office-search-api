# README

## Prerequisites

This project uses rbenv to manage the Ruby version the `.ruby-version` file.
Please make sure that's installed and configured and you will automatically
use the correct Ruby version when working with this project.

You will also need the `libpq` library installed (on a Mac, use Homebrew to
install it `brew install libpq` and then configure Bundler to use the Homebrew
version with `bundle config build.pg --with-pg-config=/opt/homebrew/opt/libpq/bin/pg_config`).

You can now run `bundle` to have a copy of your dependencies available in
your local environment.

Finally, you must now add the following to your hosts file:

```
127.0.0.1	local-office-search-api.test
```

## Starting a local copy

The easiest way to start a local copy of the app is to use Docker. First, run
`docker-compose up` to initialise all the containers, and then <kbd>Ctrl</kbd>
<kbd>C</kbd> to quit it. Now you can run `docker-compose start` to start them
in the background where they're not in your way!

You should then be able to hit the app at http://local-office-search-api.test:3060/.

## Running tests

TBC
